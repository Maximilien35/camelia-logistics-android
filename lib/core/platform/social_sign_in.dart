/// Connexion Google / Apple côté appareil (`06c` § 6c.3, § 6c.4, lot 8).
///
/// Le SDK du fournisseur **prouve une identité**, il n'ouvre aucune session :
/// il rend un jeton d'identité, que l'app envoie à `POST /auth/social/<p>/`.
/// Le backend le vérifie une fois puis rend le couple JWT Camelia — un jeton
/// Google ou Apple n'est jamais utilisé comme jeton d'API.
///
/// Cette couche isole les deux SDK derrière [SocialSignIn] : le contrôleur
/// d'authentification et ses tests ne dépendent d'aucun canal de plateforme.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../config/env.dart';

/// Fournisseur d'identité, valeur exacte du chemin et de `social_providers`.
enum SocialProvider {
  google('google'),
  apple('apple');

  const SocialProvider(this.wire);

  final String wire;
}

/// Ce que le SDK a rendu, prêt à partir vers le backend.
sealed class SocialCredential {
  const SocialCredential({this.givenName, this.familyName});

  SocialProvider get provider;

  /// Prénom et nom rendus par le SDK, s'il en rend. Apple ne les donne **qu'à
  /// la toute première autorisation** et jamais dans le jeton : l'app les
  /// transmet dès le premier appel et les garde pour le second (§ 6c.4).
  final String? givenName;
  final String? familyName;

  /// Champs propres au fournisseur, noms exacts des serializers.
  Map<String, String> get tokenFields;
}

/// `GoogleSignInSerializer` : `id_token`.
class GoogleCredential extends SocialCredential {
  const GoogleCredential({required this.idToken});

  final String idToken;

  @override
  SocialProvider get provider => SocialProvider.google;

  @override
  Map<String, String> get tokenFields => {'id_token': idToken};
}

/// `AppleSignInSerializer` : `identity_token`, `authorization_code` et le
/// `nonce` **en clair** — Apple n'a reçu que son SHA-256, le serveur le
/// recalcule et le compare à la revendication du jeton.
class AppleCredential extends SocialCredential {
  const AppleCredential({
    required this.identityToken,
    required this.authorizationCode,
    required this.nonce,
    super.givenName,
    super.familyName,
  });

  final String identityToken;
  final String authorizationCode;
  final String nonce;

  @override
  SocialProvider get provider => SocialProvider.apple;

  @override
  Map<String, String> get tokenFields => {
    'identity_token': identityToken,
    'authorization_code': authorizationCode,
    'nonce': nonce,
  };

  /// Même jeton, noms d'une autorisation précédente : un nouvel appel au SDK
  /// (jeton expiré) ne rend plus le nom, qu'il ne faut pas perdre.
  AppleCredential withNamesFrom(SocialCredential? previous) => AppleCredential(
    identityToken: identityToken,
    authorizationCode: authorizationCode,
    nonce: nonce,
    givenName: givenName ?? previous?.givenName,
    familyName: familyName ?? previous?.familyName,
  );
}

/// Le SDK n'a pas pu rendre de jeton (configuration, service système absent).
/// Distinct d'une annulation, qui n'est pas une erreur.
class SocialSignInFailed implements Exception {
  const SocialSignInFailed(this.provider, this.cause);

  final SocialProvider provider;
  final Object cause;

  @override
  String toString() => 'SocialSignInFailed(${provider.wire}, $cause)';
}

/// Fournisseurs à proposer, selon la plate-forme et la configuration du build.
///
/// - **Apple : iOS seulement** (décision D1, § 6c.4) — sur Android il n'existe
///   qu'un flux web fragile, non retenu ;
/// - **Google sur iOS seulement si Apple y est aussi** : la guideline App Store
///   4.8 impose une option équivalente respectueuse de la vie privée dès
///   qu'une connexion tierce est proposée, et Sign in with Apple est celle qui
///   la remplit sans négociation. Proposer Google seul sur iOS ferait rejeter
///   l'app ;
/// - ailleurs (web, desktop) : aucun.
List<SocialProvider> socialProvidersFor({
  required TargetPlatform platform,
  required bool googleConfigured,
  required bool appleConfigured,
}) => switch (platform) {
  TargetPlatform.android => [if (googleConfigured) SocialProvider.google],
  TargetPlatform.iOS => [
    if (appleConfigured) SocialProvider.apple,
    if (appleConfigured && googleConfigured) SocialProvider.google,
  ],
  _ => const [],
};

/// Accès aux SDK d'identité.
abstract interface class SocialSignIn {
  /// Fournisseurs à afficher sur cet appareil, dans l'ordre d'affichage.
  List<SocialProvider> get available;

  /// Ouvre le SDK. `null` si l'utilisateur annule ; [SocialSignInFailed] si
  /// le SDK échoue.
  Future<SocialCredential?> obtain(SocialProvider provider);
}

/// Aucun fournisseur : tests, plate-formes sans SDK.
class NoSocialSignIn implements SocialSignIn {
  const NoSocialSignIn();

  @override
  List<SocialProvider> get available => const [];

  @override
  Future<SocialCredential?> obtain(SocialProvider provider) async =>
      throw SocialSignInFailed(provider, 'aucun fournisseur configuré');
}

/// Les vrais SDK : `google_sign_in` 7.x et `sign_in_with_apple`.
class PlatformSocialSignIn implements SocialSignIn {
  PlatformSocialSignIn();

  Future<void>? _googleInit;

  @override
  List<SocialProvider> get available => kIsWeb
      ? const []
      : socialProvidersFor(
          platform: defaultTargetPlatform,
          googleConfigured: Env.googleServerClientId.isNotEmpty,
          appleConfigured: Env.appleSignInEnabled,
        );

  @override
  Future<SocialCredential?> obtain(SocialProvider provider) =>
      switch (provider) {
        SocialProvider.google => _google(),
        SocialProvider.apple => _apple(),
      };

  Future<SocialCredential?> _google() async {
    try {
      // `initialize` ne s'appelle qu'une fois par processus.
      await (_googleInit ??= GoogleSignIn.instance.initialize(
        serverClientId: Env.googleServerClientId,
      ));
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const SocialSignInFailed(SocialProvider.google, 'idToken nul');
      }
      // Nom et prénom sont dans le jeton (`given_name`, `family_name`) : le
      // serveur les lit lui-même pour pré-remplir.
      return GoogleCredential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw SocialSignInFailed(SocialProvider.google, e);
    }
  }

  Future<SocialCredential?> _apple() async {
    final nonce = _randomNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Apple reçoit le SHA-256 ; le backend reçoit le nonce en clair.
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const SocialSignInFailed(
          SocialProvider.apple,
          'identityToken nul',
        );
      }
      return AppleCredential(
        identityToken: identityToken,
        authorizationCode: credential.authorizationCode,
        nonce: nonce,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw SocialSignInFailed(SocialProvider.apple, e);
    } on SignInWithAppleException catch (e) {
      throw SocialSignInFailed(SocialProvider.apple, e);
    }
  }

  /// 32 caractères tirés d'un générateur cryptographique — dans les 16 à 128
  /// caractères acceptés par `AppleSignInSerializer.nonce`.
  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
