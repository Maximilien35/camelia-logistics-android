// Régression : fermer le dialogue libérait le `TextEditingController` pendant
// l'animation de fermeture (« TextEditingController was used after being
// disposed »), sur l'écran A4 puis sur « Adresses favorites ».

import 'package:camelia/features/client/widgets/favorite_label_dialog.dart';
import 'package:camelia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Future<String?>> pumpAndOpen(WidgetTester tester) async {
    late BuildContext host;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            host = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final result = showFavoriteLabelDialog(host, initial: 'Maison');
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('enregistrer : renvoie le nom, animation de fermeture sans '
      'erreur', (tester) async {
    final result = await pumpAndOpen(tester);

    await tester.enterText(find.byType(TextField), 'Travail');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(await result, 'Travail');
    expect(tester.takeException(), isNull);
  });

  testWidgets('annuler : renvoie null, animation de fermeture sans erreur', (
    tester,
  ) async {
    final result = await pumpAndOpen(tester);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(await result, isNull);
    expect(tester.takeException(), isNull);
  });
}
