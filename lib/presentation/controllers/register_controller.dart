import 'package:get/get.dart';

import '../../core/auth/auth_service.dart';
import 'auth_session_controller.dart';

class RegisterController extends GetxController {
  RegisterController(this._service, this._session);

  final AuthService _service;
  final AuthSessionController _session;

  final isBusy = false.obs;
  final registered = false.obs;
  final error = RxnString();

  Future<bool> register(String email, String password) async {
    if (isBusy.value) return false;
    isBusy.value = true;
    error.value = null;
    try {
      if (!await _service.registerEmail(email, password)) {
        error.value = _service.lastError;
        return false;
      }
      _session.markLogin();
      registered.value = true;
      return true;
    } finally {
      isBusy.value = false;
    }
  }
}
