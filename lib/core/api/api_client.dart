/// Client HTTP unique de l'app vers l'API Camelia.
///
/// Toute la logique d'appel réseau vit ici et dans les services de domaine
/// (`OrderService`, `AuthService`, ...) — **jamais dans un widget** (convention
/// CLAUDE.md). Aucune URL n'est écrite dans ce fichier : elles viennent toutes
/// d'[Env.endpoint] (règle non négociable n°2).
///
/// Ce client n'ouvre **aucune connexion persistante** : pas de WebSocket, pas de
/// streaming, pas de sondage en arrière-plan (règle non négociable n°5). Le
/// rafraîchissement du suivi de commande est un `GET` déclenché par une
/// notification push ou une action de l'utilisateur.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../config/env.dart';
import '../auth/token_store.dart';
import 'api_exception.dart';

/// Un fichier à joindre à une requête multipart.
///
/// `POST /v1/orders/`, `/driver/documents/`, `pickup-proof/`,
/// `delivery-proof/` et `confirm-return/` sont **tous** en
/// `multipart/form-data` côté backend (`MultiPartParser`, `FormParser`) — pas
/// en JSON.
class ApiFileField {
  const ApiFileField({
    required this.field,
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  /// Nom du champ attendu par le serializer (`package_photo`, `photo`, `file`).
  final String field;
  final String filename;
  final List<int> bytes;

  /// Le backend revalide le type : seuls `image/jpeg`, `image/png` et
  /// `image/webp` sont acceptés.
  final String contentType;
}

/// Réponse de liste paginée (`config.pagination.CappedPageNumberPagination`).
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.count,
    required this.results,
    this.next,
    this.previous,
    this.envelope = const {},
  });

  final int count;
  final List<T> results;
  final String? next;
  final String? previous;

  /// Corps brut de la réponse, champs hors pagination inclus.
  ///
  /// `GET /v1/driver/wallet/` ajoute `balance` **à côté** de `results`, pas
  /// dedans : c'est ici qu'on va le chercher.
  final Map<String, dynamic> envelope;

  bool get hasNext => next != null;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = (json['results'] as List<dynamic>? ?? const []);
    return PaginatedResponse(
      count: (json['count'] as num?)?.toInt() ?? raw.length,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: raw
          .map((e) => parse(e as Map<String, dynamic>))
          .toList(growable: false),
      envelope: json,
    );
  }
}

/// Client HTTP partagé.
class ApiClient {
  ApiClient({
    required TokenStore tokenStore,
    http.Client? httpClient,
    this.onSessionExpired,
    Duration? timeout,
  }) : _tokens = tokenStore,
       _http = httpClient ?? http.Client(),
       _timeout = timeout ?? const Duration(seconds: 30);

  final TokenStore _tokens;
  final http.Client _http;
  final Duration _timeout;

  /// Appelé quand le `refresh` est lui aussi refusé : la session est finie et
  /// l'app doit retourner à l'écran de connexion. Les jetons sont déjà effacés
  /// quand ce rappel se déclenche.
  final Future<void> Function()? onSessionExpired;

  /// Sérialise les rafraîchissements concurrents : plusieurs requêtes qui
  /// tombent en 401 en même temps ne doivent déclencher qu'**un seul**
  /// `POST /auth/refresh/`. La rotation serveur invalide l'ancien `refresh`,
  /// donc deux rafraîchissements en parallèle s'annuleraient mutuellement.
  Future<bool>? _pendingRefresh;

  void close() => _http.close();

  // --- Verbes JSON ---------------------------------------------------------

  /// [query] accepte une `String` ou une `List<String>` en valeur : le
  /// backend lit certains filtres en **paramètre répété**
  /// (`?status=a&status=b`, `MultipleChoiceField`, § 7.3.4), qu'une seule
  /// valeur séparée par des virgules ne rendrait pas.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) => _sendJson('GET', path, query: query, authenticated: authenticated);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) => _sendJson('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) => _sendJson('PATCH', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) => _sendJson('DELETE', path, body: body, authenticated: authenticated);

  /// Liste paginée.
  Future<PaginatedResponse<T>> getPage<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    int? page,
    int? pageSize,
    Map<String, String>? query,
    Map<String, List<String>>? repeatedQuery,
  }) async {
    final params = <String, dynamic>{
      if (page != null) 'page': '$page',
      // Plafonné à 100 côté serveur : demander plus ne sert à rien.
      if (pageSize != null) 'page_size': '$pageSize',
      ...?query,
      // Filtres répétés : `?status=completed&status=disputed`.
      ...?repeatedQuery,
    };
    final json = await get(path, query: params.isEmpty ? null : params);
    return PaginatedResponse.fromJson(json, parse);
  }

  /// Envoi `multipart/form-data`.
  Future<Map<String, dynamic>> multipart(
    String path, {
    Map<String, String> fields = const {},
    List<ApiFileField> files = const [],
    String method = 'POST',
    bool authenticated = true,
  }) async {
    Future<http.StreamedResponse> send() async {
      final request = http.MultipartRequest(
        method,
        Uri.parse(Env.endpoint(path)),
      );
      request.fields.addAll(fields);
      for (final f in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            f.field,
            f.bytes,
            filename: f.filename,
            contentType: _parseMediaType(f.contentType),
          ),
        );
      }
      request.headers.addAll(await _headers(authenticated: authenticated));
      return _http.send(request).timeout(_timeout);
    }

    var streamed = await _guard(send);
    if (streamed.statusCode == 401 && authenticated) {
      if (await _refresh()) {
        streamed = await _guard(send);
      }
    }
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  // --- Rafraîchissement ----------------------------------------------------

  /// Rejoue `POST /v1/auth/refresh/` et enregistre la **nouvelle paire**.
  ///
  /// `ROTATE_REFRESH_TOKENS` étant actif côté serveur, la réponse contient un
  /// nouveau `refresh` qui remplace l'ancien (mis en liste noire). Renvoie
  /// `false` si la session est définitivement perdue.
  Future<bool> _refresh() {
    return _pendingRefresh ??= _doRefresh().whenComplete(() {
      _pendingRefresh = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null) {
      await _endSession();
      return false;
    }
    final response = await _guard(
      () => _http
          .post(
            Uri.parse(Env.endpoint('auth/refresh')),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refresh}),
          )
          .timeout(_timeout),
    );
    if (response.statusCode != 200) {
      await _endSession();
      return false;
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    await _tokens.saveTokens(
      AuthTokens(
        access: json['access'] as String,
        // `TokenRefreshView` renvoie un nouveau `refresh` quand la rotation est
        // active ; on garde l'ancien si jamais il est absent.
        refresh: (json['refresh'] as String?) ?? refresh,
      ),
    );
    return true;
  }

  Future<void> _endSession() async {
    await _tokens.clear();
    await onSessionExpired?.call();
  }

  // --- Plomberie -----------------------------------------------------------

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async {
    Future<http.Response> send() async {
      final uri = Uri.parse(
        Env.endpoint(path),
      ).replace(queryParameters: query?.isEmpty ?? true ? null : query);
      final headers = await _headers(
        authenticated: authenticated,
        json: body != null,
      );
      final encoded = body == null ? null : jsonEncode(body);
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (encoded != null) request.body = encoded;
      final streamed = await _http.send(request).timeout(_timeout);
      return http.Response.fromStream(streamed);
    }

    var response = await _guard(send);
    if (response.statusCode == 401 && authenticated) {
      if (await _refresh()) {
        response = await _guard(send);
      }
    }
    return _decode(response);
  }

  Future<Map<String, String>> _headers({
    required bool authenticated,
    bool json = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    if (authenticated) {
      final access = await _tokens.readAccess();
      // `AUTH_HEADER_TYPES = ("Bearer",)` côté SimpleJWT.
      if (access != null) headers['Authorization'] = 'Bearer $access';
    }
    return headers;
  }

  /// Convertit une panne de transport en [NetworkException].
  ///
  /// Sans cela, un `SocketException` remonterait brut jusqu'à l'UI, qui ne
  /// pourrait pas le distinguer d'une erreur métier.
  Future<T> _guard<T>(Future<T> Function() send) async {
    try {
      return await send();
    } on SocketException catch (e) {
      throw NetworkException(e);
    } on HttpException catch (e) {
      throw NetworkException(e);
    } on TimeoutException catch (e) {
      throw NetworkException(e);
    }
  }

  /// Décode une réponse, ou lève une [ApiException] au format du backend.
  Map<String, dynamic> _decode(http.Response response) {
    final status = response.statusCode;
    // `204` et certains webhooks répondent sans corps.
    final hasBody = response.bodyBytes.isNotEmpty;
    Object? decoded;
    if (hasBody) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        // Réponse non-JSON : page d'erreur d'un proxy, par exemple.
        decoded = utf8.decode(response.bodyBytes, allowMalformed: true);
      }
    }

    if (status >= 200 && status < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      // Aucun endpoint mobile ne renvoie une liste nue (la pagination est
      // obligatoire côté serveur) ni un scalaire : on normalise le vide.
      return const <String, dynamic>{};
    }

    throw ApiException.fromResponse(statusCode: status, body: decoded);
  }
}

/// Convertit `"image/webp"` en [MediaType], que `http` attend sur une pièce
/// multipart.
///
/// Le type doit être posé explicitement : sans lui, `http` envoie la pièce en
/// `application/octet-stream` et le backend la rejette — il revalide le
/// `content_type` de chaque fichier (`ALLOWED_DOCUMENT_CONTENT_TYPES`,
/// `ALLOWED_PACKAGE_PHOTO_CONTENT_TYPES` : JPEG, PNG, WebP uniquement).
MediaType? _parseMediaType(String contentType) {
  try {
    return MediaType.parse(contentType);
  } on FormatException {
    return null;
  }
}
