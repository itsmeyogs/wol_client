import 'package:get/get.dart';

import '../../core/auth/auth_service.dart';
import 'auth_session_controller.dart';

class SettingsEmailController extends GetxController {
  SettingsEmailController(this._service, this._session);

  final AuthService _service;
  final AuthSessionController _session;

  final isBusy = false.obs;
  final error = RxnString();

  Future<bool> signIn(String email, String password) => _guard(() async {
    if (!await _service.signInEmail(email, password)) {
      if (_service.verificationRequired) _session.markVerification();
      error.value = _service.lastError;
      return false;
    }
    _session.markAuthenticated();
    return true;
  });

  Future<bool> createAccount(String email, String password) => _guard(() async {
    if (!await _service.registerEmailFromSettings(email, password)) {
      error.value = _service.lastError;
      return false;
    }
    _session.markAuthenticated();
    return true;
  });

  Future<bool> signInGoogle() => _guard(() async {
    if (!await _service.signInGoogle()) {
      error.value = _service.lastError;
      return false;
    }
    _session.markAuthenticated();
    return true;
  });

  Future<bool> _guard(Future<bool> Function() action) async {
    if (isBusy.value) return false;
    isBusy.value = true;
    error.value = null;
    try {
      return await action();
    } finally {
      isBusy.value = false;
    }
  }
}
