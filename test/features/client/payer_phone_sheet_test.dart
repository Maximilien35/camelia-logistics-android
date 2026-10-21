import 'package:camelia/features/client/widgets/payer_phone_sheet.dart';
import 'package:camelia/features/shared/models/phone_number.dart';
import 'package:camelia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

/// Le curseur de `Pinput` clignote tant que le champ a le focus :
/// `pumpAndSettle` n'y rendrait jamais la main. On avance l'horloge d'une
/// durée fixe, assez longue pour les transitions de la feuille.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Ouvre la feuille depuis un bouton et rend ce qu'elle a renvoyé.
Future<String? Function()> _open(
  WidgetTester tester, {
  String initialPhone = '',
}) async {
  String? result;
  var closed = false;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await showPayerPhoneSheet(
                context,
                initialPhone: initialPhone,
              );
              closed = true;
            },
            child: const Text('payer'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('payer'));
  await _settle(tester);
  return () {
    expect(closed, isTrue, reason: 'la feuille devait se fermer');
    return result;
  };
}

void main() {
  group('PhoneNumber, numéros camerounais', () {
    test('chiffres locaux, forme mobile et affichage', () {
      expect(PhoneNumber.cameroonLocal('+237670000001'), '670000001');
      expect(PhoneNumber.cameroonLocal('+33612345678'), isNull);
      expect(PhoneNumber.isCameroonMobile('670000001'), isTrue);
      expect(PhoneNumber.isCameroonMobile('233000001'), isFalse);
      expect(PhoneNumber.isCameroonMobile('67000000'), isFalse);
      expect(PhoneNumber.displayCameroon('670000001'), '+237 6 70 00 00 01');
    });
  });

  testWidgets('préremplie avec le numéro du compte, vérifiée avant l\'envoi', (
    tester,
  ) async {
    final result = await _open(tester, initialPhone: '+237670000001');

    await tester.tap(find.text('Continuer'));
    await _settle(tester);

    // Étape de vérification : le numéro en grand, rien n'est encore rendu.
    expect(find.text('Vérifiez le numéro'), findsOneWidget);
    expect(find.text('+237 6 70 00 00 01'), findsOneWidget);

    await tester.tap(find.text('Oui, envoyer la demande'));
    await _settle(tester);

    expect(result(), '+237670000001');
  });

  testWidgets('un numéro qui ne commence pas par 6 est refusé sur place', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(find.byType(Pinput), '233445566');
    await _settle(tester);

    expect(find.textContaining('commence par 6'), findsOneWidget);
    expect(find.text('Vérifiez le numéro'), findsNothing);
  });

  testWidgets('« Modifier le numéro » revient à la saisie', (tester) async {
    await _open(tester);

    // Les 9 chiffres saisis passent d'eux-mêmes à la vérification.
    await tester.enterText(find.byType(Pinput), '690000002');
    await _settle(tester);
    expect(find.text('+237 6 90 00 00 02'), findsOneWidget);

    await tester.tap(find.text('Modifier le numéro'));
    await _settle(tester);

    expect(find.byType(Pinput), findsOneWidget);
    expect(find.text('Vérifiez le numéro'), findsNothing);
  });
}
