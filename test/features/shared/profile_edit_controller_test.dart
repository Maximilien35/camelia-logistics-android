import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/features/shared/models/app_user.dart';
import 'package:camelia/features/shared/services/profile_service.dart';
import 'package:camelia/features/shared/state/profile_edit_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_session.dart';

/// Contrat proposé C3, contre le faux serveur.
void main() {
  late MockSession session;
  late ProfileEditController controller;
  AppUser? applied;

  setUp(() async {
    session = MockSession();
    applied = null;
    controller = ProfileEditController(
      service: ProfileService(client: session.client),
      onProfileUpdated: (user) => applied = user,
    );
    await session.signIn('aicha@camelia.test');
  });

  test('prénom et nom : le profil appliqué est celui du serveur', () async {
    final ok = await controller.saveName(
      firstName: '  Aïcha ',
      lastName: 'Ngo',
    );

    expect(ok, isTrue);
    expect(applied?.firstName, 'Aïcha');
    expect(applied?.lastName, 'Ngo');
    expect((await session.auth.fetchMe()).lastName, 'Ngo');
  });

  test('un nom vide est refusé sans appel réseau', () async {
    expect(await controller.saveName(firstName: '', lastName: 'Ngo'), isFalse);
    expect(applied, isNull);
    expect(controller.nameFailure, isNull);
  });

  test('téléphone : le numéro ne change qu\'après le code', () async {
    controller.startPhoneChange();
    expect(await controller.requestCode('6 99 11 22 33'), isTrue);
    expect(controller.phoneStep, PhoneChangeStep.awaitingCode);
    expect(controller.pendingPhone, '+237699112233');
    // Pas encore changé côté serveur.
    expect((await session.auth.fetchMe()).phone, '+237690000001');

    expect(await controller.confirmCode('482109'), isTrue);
    expect(applied?.phone, '+237699112233');
    expect(controller.phoneStep, PhoneChangeStep.idle);
  });

  test('numéro mal formé : refusé localement', () async {
    controller.startPhoneChange();
    expect(await controller.requestCode('12 34'), isFalse);
    expect(controller.phoneFailure, isNull);
    expect(controller.phoneStep, PhoneChangeStep.enteringNumber);
  });

  test('numéro d\'un autre compte → phone_already_used', () async {
    controller.startPhoneChange();
    // Numéro du chauffeur de démonstration.
    expect(await controller.requestCode('+237690000002'), isFalse);
    expect(
      controller.phoneFailure,
      isA<ApiException>().having(
        (e) => e.code,
        'code',
        ApiErrorCode.phoneAlreadyUsed,
      ),
    );
  });

  test('code incorrect → invalid_otp, numéro inchangé', () async {
    controller.startPhoneChange();
    await controller.requestCode('699112233');

    expect(await controller.confirmCode('000000'), isFalse);
    expect(
      controller.phoneFailure,
      isA<ApiException>().having(
        (e) => e.code,
        'code',
        ApiErrorCode.invalidOtp,
      ),
    );
    expect(applied, isNull);
    expect(controller.phoneStep, PhoneChangeStep.awaitingCode);
  });
}
