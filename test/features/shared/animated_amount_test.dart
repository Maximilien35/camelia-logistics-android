import 'package:camelia/features/shared/widgets/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(String? raw, {bool reduceMotion = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: AnimatedAmount(raw, style: const TextStyle()),
  ),
);

void main() {
  testWidgets('la dernière image affiche exactement le montant du serveur', (
    tester,
  ) async {
    await tester.pumpWidget(_host('12400.50'));
    await tester.pumpAndSettle();

    // Décimales comprises : l'animation n'arrondit jamais la valeur finale.
    expect(find.text(formatAmount('12400.50')), findsOneWidget);
  });

  testWidgets('pendant le défilement, une valeur intermédiaire', (
    tester,
  ) async {
    await tester.pumpWidget(_host('12400'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(formatAmount('12400')), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text(formatAmount('12400')), findsOneWidget);
  });

  testWidgets('montant absent : un tiret, sans animation', (tester) async {
    await tester.pumpWidget(_host(null));
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('animations réduites : la valeur tout de suite', (tester) async {
    await tester.pumpWidget(_host('2529', reduceMotion: true));
    expect(find.text(formatAmount('2529')), findsOneWidget);
  });
}
