import 'package:camelia/core/api/mock/mock_social_sign_in.dart';
import 'package:camelia/core/platform/social_sign_in.dart';
import 'package:camelia/features/shared/screens/auth/login_screen.dart';
import 'package:camelia/features/shared/screens/auth/social_completion_screen.dart';
import 'package:camelia/features/shared/state/auth_controller.dart';
import 'package:camelia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/mock_session.dart';

Future<void> _pumpLogin(WidgetTester tester, SocialSignIn social) async {
  // Surface de test par défaut : la police de test dessine chaque caractère
  // en carré d'un cadratin, une largeur de téléphone ferait déborder des
  // lignes qui tiennent très bien avec la vraie police.
  final session = MockSession();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthController(service: session.auth, social: social),
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('fr'),
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans fournisseur configuré, l\'écran garde sa forme d\'avant', (
    tester,
  ) async {
    await _pumpLogin(tester, const NoSocialSignIn());

    expect(find.text('Continuer avec Google'), findsNothing);
    expect(find.text('Continuer avec Apple'), findsNothing);
  });

  testWidgets('Google, compte inconnu : l\'écran de complétion s\'ouvre, '
      'prérempli', (tester) async {
    await _pumpLogin(tester, MockSocialSignIn());

    expect(find.text('Continuer avec Apple'), findsOneWidget);
    final google = find.text('Continuer avec Google');
    expect(google, findsOneWidget);

    await tester.ensureVisible(google);
    await tester.tap(google);
    await tester.pumpAndSettle();

    expect(find.byType(SocialCompletionScreen), findsOneWidget);
    expect(find.text('nadia.google@camelia.test'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Nadia'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ekambi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
