import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:camelia/features/shared/screens/auth/register_screen.dart';
import 'package:camelia/features/shared/services/auth_service.dart';
import 'package:camelia/features/shared/state/auth_controller.dart';
import 'package:camelia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

class _NoTokenStore extends TokenStore {
  @override
  Future<String?> readAccess() async => null;

  @override
  Future<String?> readRefresh() async => null;

  @override
  Future<void> clear() async {}
}

Future<void> _pumpRegister(WidgetTester tester) async {
  final store = _NoTokenStore();
  final client = ApiClient(
    tokenStore: store,
    httpClient: MockClient((_) async => http.Response('{}', 200)),
  );
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthController(
        service: AuthService(client: client, tokenStore: store),
      ),
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('fr'), Locale('en')],
        locale: Locale('fr'),
        home: RegisterScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Avance l'animation image par image en relevant toute erreur de layout :
/// un débordement qui ne dure que le temps de l'animation ne se voit pas
/// après un simple `pumpAndSettle`.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 25));
    expect(tester.takeException(), isNull, reason: 'image n°$i');
  }
  await tester.pumpAndSettle();
}

void main() {
  // Écran plus court que le formulaire d'inscription : c'est là que le
  // gabarit, mesuré par `IntrinsicHeight`, n'a plus de marge.
  testWidgets('inscription : (dés)activer « chauffeur » ne déborde jamais', (
    tester,
  ) async {
    await _pumpRegister(tester);
    final toggle = find.text('Je veux devenir chauffeur');

    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await _pumpFrames(tester);

    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await _pumpFrames(tester);
  });

  testWidgets('un message d\'erreur de champ qui disparaît ne déborde pas', (
    tester,
  ) async {
    await _pumpRegister(tester);

    // Mot de passe trop court : message sous le champ. Chaque champ est
    // d'abord amené à l'écran, sinon il ne reçoit pas le focus.
    final fields = find.byType(TextField);
    Future<void> type(int index, String text) async {
      await tester.ensureVisible(fields.at(index));
      await tester.enterText(fields.at(index), text);
    }

    await type(0, 'Aïcha');
    await type(1, 'Ngono');
    await type(2, 'aicha@example.cm');
    await type(3, '+237690000000');
    await type(4, 'abc');
    // Clavier fermé avant d'aller au bouton, comme un vrai utilisateur : un
    // champ encore actif ramène le défilement sur lui à l'image suivante, et
    // le tap tomberait à côté.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();
    expect(
      find.text('Le mot de passe doit faire au moins 8 caractères.'),
      findsOneWidget,
    );

    // La saisie efface le message : il se replie.
    await type(4, 'abcd');
    await _pumpFrames(tester);
  });
}
