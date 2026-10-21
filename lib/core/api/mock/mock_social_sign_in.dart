/// Faux SDK Google / Apple du mode simulé (`USE_MOCK_API=true`).
///
/// Rend des « jetons » lisibles par `MockBackend`
/// (`mock:<email>:<prénom>:<nom>`), pour éprouver les trois issues de la connexion sociale sans compte
/// développeur ni appareil réel :
/// - **Google** : un compte inconnu → complétion du téléphone, puis création ;
///   la fois suivante, simple connexion ;
/// - **Apple** : l'email d'un compte existant (Aïcha) → rattachement et
///   connexion directe. Le nom n'est rendu qu'à la « première autorisation »,
///   comme le vrai SDK.
///
/// Les deux boutons s'affichent quelle que soit la plate-forme : le mode
/// simulé sert à voir les écrans, pas à vérifier la règle iOS / Android.
library;

import '../../platform/social_sign_in.dart';

class MockSocialSignIn implements SocialSignIn {
  bool _appleAuthorizedOnce = false;

  @override
  List<SocialProvider> get available => const [
    SocialProvider.apple,
    SocialProvider.google,
  ];

  @override
  Future<SocialCredential?> obtain(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        return const GoogleCredential(
          idToken: 'mock:nadia.google@camelia.test:Nadia:Ekambi',
        );
      case SocialProvider.apple:
        final first = !_appleAuthorizedOnce;
        _appleAuthorizedOnce = true;
        return AppleCredential(
          identityToken: 'mock:aicha@camelia.test::',
          authorizationCode: 'mock-code',
          nonce: 'mock-nonce-0123456789abcdef',
          givenName: first ? 'Aïcha' : null,
          familyName: first ? 'Ngono' : null,
        );
    }
  }
}
