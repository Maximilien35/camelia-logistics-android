import 'package:camelia/features/shared/widgets/camelia_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camelia/core/theme/app_icons.dart';

const _items = [
  BottomBarItem(
    label: 'Accueil',
    icon: AppIcons.home,
    activeIcon: AppIcons.homeActive,
  ),
  BottomBarItem(
    label: 'Commandes',
    icon: AppIcons.orders,
    activeIcon: AppIcons.ordersActive,
  ),
  BottomBarItem(
    label: 'Portefeuille',
    icon: AppIcons.earnings,
    activeIcon: AppIcons.earningsActive,
  ),
  BottomBarItem(
    label: 'Compte',
    icon: AppIcons.account,
    activeIcon: AppIcons.accountActive,
  ),
];

/// Position horizontale attendue de la pastille pour l'onglet [index].
///
/// Calculee depuis la largeur reellement mesuree, pas depuis une constante :
/// la surface de test ne fait pas la taille passee a `MediaQuery`, et coder un
/// nombre en dur rendrait le test faux sur une autre surface.
double _expectedPillX(WidgetTester tester, int index, int count) {
  final bar = tester.getRect(find.byType(CameliaBottomBar));
  const horizontalPadding = 16.0;
  const pillWidth = 56.0;
  final slot = (bar.width - horizontalPadding * 2) / count;
  return bar.left + horizontalPadding + slot * index + (slot - pillWidth) / 2;
}

Widget _bar({
  required int currentIndex,
  required ValueChanged<int> onChanged,
  bool disableAnimations = false,
  List<BottomBarItem> items = _items,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(400, 800),
      disableAnimations: disableAnimations,
    ),
    child: MaterialApp(
      home: Scaffold(
        bottomNavigationBar: CameliaBottomBar(
          items: items,
          currentIndex: currentIndex,
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

/// Position horizontale **réellement rendue** de la pastille.
///
/// `AnimatedPositioned.left` porte la cible, pas l'état courant : lire la
/// géométrie est le seul moyen de prouver que l'interpolation a lieu.
double _pillX(WidgetTester tester) =>
    tester.getTopLeft(find.byType(AnimatedPositioned)).dx;

void main() {
  group('Rendu', () {
    testWidgets('affiche un libellé par onglet', (tester) async {
      await tester.pumpWidget(_bar(currentIndex: 0, onChanged: (_) {}));
      await tester.pumpAndSettle();

      for (final item in _items) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('la barre du chauffeur accepte trois onglets', (tester) async {
      await tester.pumpWidget(
        _bar(
          currentIndex: 0,
          onChanged: (_) {},
          items: const [
            BottomBarItem(
              label: 'Courses',
              icon: AppIcons.jobs,
              activeIcon: AppIcons.jobsActive,
            ),
            BottomBarItem(
              label: 'Gains',
              icon: AppIcons.earnings,
              activeIcon: AppIcons.earningsActive,
            ),
            BottomBarItem(
              label: 'Profil',
              icon: AppIcons.account,
              activeIcon: AppIcons.accountActive,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Gains'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });
  });

  group('Sélection', () {
    testWidgets('un autre onglet remonte son index', (tester) async {
      var received = -1;
      await tester.pumpWidget(
        _bar(currentIndex: 0, onChanged: (i) => received = i),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Compte'));
      await tester.pumpAndSettle();

      expect(received, 3);
    });

    testWidgets('chaque onglet remonte le bon index', (tester) async {
      final recus = <int>[];
      await tester.pumpWidget(_bar(currentIndex: 0, onChanged: recus.add));
      await tester.pumpAndSettle();

      for (final label in ['Commandes', 'Portefeuille', 'Compte']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      expect(recus, [1, 2, 3]);
    });

    testWidgets('toucher l\'onglet déjà actif ne déclenche rien', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(_bar(currentIndex: 1, onChanged: (_) => calls++));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Commandes'));
      await tester.pumpAndSettle();

      // Rejouer l'onglet courant relancerait l'animation et le retour haptique
      // pour rien.
      expect(calls, 0);
    });
  });

  group('Pastille animée', () {
    testWidgets('se place sous l\'onglet actif', (tester) async {
      await tester.pumpWidget(_bar(currentIndex: 0, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect(_pillX(tester), closeTo(_expectedPillX(tester, 0, 4), 0.5));

      await tester.pumpWidget(_bar(currentIndex: 2, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect(_pillX(tester), closeTo(_expectedPillX(tester, 2, 4), 0.5));
    });

    testWidgets('glisse au lieu de sauter quand l\'index change', (
      tester,
    ) async {
      await tester.pumpWidget(_bar(currentIndex: 0, onChanged: (_) {}));
      await tester.pumpAndSettle();
      final depart = _pillX(tester);

      await tester.pumpWidget(_bar(currentIndex: 3, onChanged: (_) {}));
      // À mi-parcours (l'animation dure 280 ms), la pastille doit être
      // strictement entre le départ et l'arrivée : c'est la preuve du
      // glissement, qu'un simple saut ne produirait pas.
      await tester.pump(const Duration(milliseconds: 140));
      final milieu = _pillX(tester);

      final arrivee = _expectedPillX(tester, 3, 4);
      expect(depart, closeTo(_expectedPillX(tester, 0, 4), 0.5));
      expect(milieu, greaterThan(depart + 1));
      expect(milieu, lessThan(arrivee - 1));

      await tester.pumpAndSettle();
      expect(_pillX(tester), closeTo(arrivee, 0.5));
    });

    testWidgets(
      'se repositionne sans transition si les animations sont coupées',
      (tester) async {
        // Accessibilité : `disableAnimations` doit supprimer le glissement.
        await tester.pumpWidget(
          _bar(currentIndex: 0, onChanged: (_) {}, disableAnimations: true),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          _bar(currentIndex: 3, onChanged: (_) {}, disableAnimations: true),
        );
        // Une seule image : la pastille est déjà arrivée, sans interpolation.
        await tester.pump();

        expect(_pillX(tester), closeTo(_expectedPillX(tester, 3, 4), 0.5));
        expect(
          tester
              .widget<AnimatedPositioned>(find.byType(AnimatedPositioned))
              .duration,
          Duration.zero,
        );
      },
    );
  });

  group('Accessibilité', () {
    testWidgets('l\'onglet actif est annoncé comme sélectionné', (
      tester,
    ) async {
      await tester.pumpWidget(_bar(currentIndex: 1, onChanged: (_) {}));
      await tester.pumpAndSettle();

      // On verifie la configuration `Semantics` posee par la barre, plutot que
      // l'arbre de semantique complet : `matchesSemantics` exige d'enumerer
      // toutes les actions, ce qui casse des qu'InkWell en ajoute une.
      Semantics semanticsFor(String label) => tester
          .widgetList<Semantics>(find.byType(Semantics))
          .firstWhere((s) => s.properties.label == label);

      expect(semanticsFor('Commandes').properties.selected, isTrue);
      expect(semanticsFor('Commandes').properties.button, isTrue);
      expect(semanticsFor('Accueil').properties.selected, isFalse);
    });
  });
}
