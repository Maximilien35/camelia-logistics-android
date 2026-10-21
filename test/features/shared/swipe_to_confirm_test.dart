import 'package:camelia/features/shared/widgets/swipe_to_confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({VoidCallback? onConfirmed, bool busy = false}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: SwipeToConfirm(
          label: 'Glisser pour accepter',
          onConfirmed: onConfirmed,
          busy: busy,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('un glissement jusqu\'au bout confirme', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(onConfirmed: () => calls++));

    await tester.drag(find.byType(SwipeToConfirm), const Offset(320, 0));
    await tester.pumpAndSettle();

    expect(calls, 1);
  });

  testWidgets('un glissement trop court ne confirme rien et revient', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(_host(onConfirmed: () => calls++));

    // La moitié de la course : en deçà du seuil de 85 %.
    await tester.drag(find.byType(SwipeToConfirm), const Offset(120, 0));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('un simple appui ne confirme rien', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(onConfirmed: () => calls++));

    await tester.tap(find.byType(SwipeToConfirm));
    await tester.pumpAndSettle();

    // C'est tout l'intérêt du contrôle : au volant, un effleurement ne doit
    // pas accepter une course.
    expect(calls, 0);
  });

  testWidgets('désactivé, il ne confirme jamais', (tester) async {
    await tester.pumpWidget(_host());

    await tester.drag(find.byType(SwipeToConfirm), const Offset(320, 0));
    await tester.pumpAndSettle();

    // Aucun rappel à appeler : le test vérifie surtout l'absence d'erreur.
    expect(find.byType(SwipeToConfirm), findsOneWidget);
  });

  testWidgets('un lecteur d\'écran peut confirmer sans glisser', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(_host(onConfirmed: () => calls++));

    // Le contrôle s'annonce comme un bouton dont l'action « activer »
    // confirme directement.
    final node = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Glisser pour accepter',
      ),
    );
    expect(node.properties.button, isTrue);
    node.properties.onTap!();
    await tester.pumpAndSettle();

    expect(calls, 1);
  });
}
