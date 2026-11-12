import 'package:get/get.dart';

import '../../core/auth/auth_service.dart';

class SettingsPasswordController extends GetxController {
  SettingsPasswordController(this._service);

  final AuthService _service;
  final isBusy = false.obs;
  final error = RxnString();

  Future<bool> submit({
    required bool setPassword,
    required String password,
    required String currentPassword,
  }) async {
    if (isBusy.value) return false;
    isBusy.value = true;
    error.value = null;
    try {
      final ok = setPassword
          ? await _service.linkEmailPassword(password)
          : await _service.changeEmailPassword(password, currentPassword);
      if (!ok) error.value = _service.lastError;
      return ok;
    } finally {
      isBusy.value = false;
    }
  }
}
