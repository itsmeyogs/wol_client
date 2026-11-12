import 'package:get/get.dart';

import '../../core/auth/auth_service.dart';
import 'auth_session_controller.dart';

class EmailVerificationController extends GetxController {
  EmailVerificationController(this._service, this._session);

  final AuthService _service;
  final AuthSessionController _session;

  final isBusy = false.obs;
  final error = RxnString();
  String? get email => _service.currentUser?.email;

  Future<bool> check() => _guard(() async {
    if (!await _service.checkEmailVerification()) {
      error.value = _service.lastError;
      return false;
    }
    _session.markAuthenticated();
    return true;
  });

  Future<bool> resend() => _guard(() async {
    if (!await _service.resendVerificationEmail()) {
      error.value = _service.lastError;
      return false;
    }
    return true;
  });

  Future<void> logOut() async {
    await _session.signOutUnverified();
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
