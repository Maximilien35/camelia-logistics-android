/// État de l'écran « Informations personnelles » — § 7.3.8, livré par T5.10.
///
/// Deux actions indépendantes :
/// - **prénom / nom** : un seul `PATCH /v1/me/` ;
/// - **téléphone** : demande de code au nouveau numéro, puis validation. Le
///   numéro du compte ne change qu'**après** la validation par le serveur.
///
/// Le profil affiché ensuite est toujours celui **renvoyé par le serveur**
/// (`AuthController.applyServerProfile`), jamais la saisie.
library;

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../models/app_user.dart';
import '../models/phone_number.dart';
import '../services/profile_service.dart';

enum PhoneChangeStep { idle, enteringNumber, awaitingCode }

class ProfileEditController extends ChangeNotifier {
  ProfileEditController({
    required ProfileService service,
    required void Function(AppUser) onProfileUpdated,
  }) : _service = service,
       _onProfileUpdated = onProfileUpdated;

  final ProfileService _service;
  final void Function(AppUser) _onProfileUpdated;

  static const int maxNameLength = 150;
  static const int codeLength = 6;

  bool _savingName = false;
  Object? _nameFailure;

  PhoneChangeStep _phoneStep = PhoneChangeStep.idle;
  String _pendingPhone = '';
  bool _phoneBusy = false;
  Object? _phoneFailure;

  bool get savingName => _savingName;
  Object? get nameFailure => _nameFailure;

  PhoneChangeStep get phoneStep => _phoneStep;

  /// Numéro en cours de vérification, au format E.164.
  String get pendingPhone => _pendingPhone;
  bool get phoneBusy => _phoneBusy;
  Object? get phoneFailure => _phoneFailure;

  /// Erreur de forme sur un nom, ou `null`.
  static String? nameProblem(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'required';
    if (trimmed.length > maxNameLength) return 'too_long';
    return null;
  }

  Future<bool> saveName({
    required String firstName,
    required String lastName,
  }) async {
    if (nameProblem(firstName) != null || nameProblem(lastName) != null) {
      return false;
    }
    _savingName = true;
    _nameFailure = null;
    notifyListeners();
    try {
      _onProfileUpdated(
        await _service.updateName(firstName: firstName, lastName: lastName),
      );
      return true;
    } on ApiException catch (e) {
      _nameFailure = e;
      return false;
    } on NetworkException catch (e) {
      _nameFailure = e;
      return false;
    } finally {
      _savingName = false;
      notifyListeners();
    }
  }

  void startPhoneChange() {
    _phoneStep = PhoneChangeStep.enteringNumber;
    _phoneFailure = null;
    notifyListeners();
  }

  void cancelPhoneChange() {
    _phoneStep = PhoneChangeStep.idle;
    _pendingPhone = '';
    _phoneFailure = null;
    notifyListeners();
  }

  /// Demande un code pour [input], saisi à la camerounaise ou en E.164.
  /// Renvoie `false` sur un numéro mal formé, sans appel réseau.
  Future<bool> requestCode(String input) async {
    final phone = PhoneNumber.normalize(input);
    if (!PhoneNumber.isE164(phone)) return false;
    return _runPhone(() async {
      await _service.requestPhoneChange(phone);
      _pendingPhone = phone;
      _phoneStep = PhoneChangeStep.awaitingCode;
    });
  }

  Future<bool> confirmCode(String code) async {
    if (_phoneStep != PhoneChangeStep.awaitingCode ||
        code.length != codeLength) {
      return false;
    }
    return _runPhone(() async {
      final user = await _service.confirmPhoneChange(
        phone: _pendingPhone,
        code: code,
      );
      _onProfileUpdated(user);
      _phoneStep = PhoneChangeStep.idle;
      _pendingPhone = '';
    });
  }

  Future<bool> _runPhone(Future<void> Function() action) async {
    _phoneBusy = true;
    _phoneFailure = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _phoneFailure = e;
      return false;
    } on NetworkException catch (e) {
      _phoneFailure = e;
      return false;
    } finally {
      _phoneBusy = false;
      notifyListeners();
    }
  }
}
