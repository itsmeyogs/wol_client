import 'package:get/get.dart';

import '../../core/auth/auth_service.dart';
import 'auth_session_controller.dart';

class LoginController extends GetxController {
  LoginController(this._service, this._session);

  final AuthService _service;
  final AuthSessionController _session;

  final isBusy = false.obs;
  final error = RxnString();
  bool get needsGoogleLinkPassword => _service.needsGoogleLinkPassword;

  Future<bool> signInEmail(String email, String password) => _guard(() async {
    if (!await _service.signInEmail(email, password)) {
      if (_service.verificationRequired) _session.markVerification();
      error.value = _service.lastError;
      return false;
    }
    _session.markAuthenticated();
    return true;
  });

  Future<bool> signInGoogle() => _guard(() async {
    if (await _service.signInGoogle()) {
      _session.markAuthenticated();
      return true;
    }
    error.value = _service.lastError;
    return false;
  });

  Future<bool> completeGoogleLink(String password) => _guard(() async {
    if (!await _service.completeGoogleLink(password)) {
      error.value = _service.lastError;
      return false;
    }
    _session.markAuthenticated();
    return true;
  });

  Future<void> continueAsGuest() async {
    await _session.continueAsGuest();
  }

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
