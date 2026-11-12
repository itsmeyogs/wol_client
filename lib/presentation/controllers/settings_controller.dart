import 'package:get/get.dart';

import '../../core/auth/auth_mode.dart';
import '../../core/auth/auth_service.dart';
import '../../data/datasources/gateway_cloud_data_source.dart';
import 'auth_session_controller.dart';

class SettingsController extends GetxController {
  SettingsController(this._service, this._session);

  final AuthService _service;
  final AuthSessionController _session;

  final isBusy = false.obs;
  final error = RxnString();

  bool get isGuest => _session.mode.value == AuthMode.guest;
  bool get needsEmailVerification => _session.needsEmailVerification;
  bool get canSetPassword => _service.canSetPassword;
  bool get hasPassword =>
      _service.currentUser?.providerData.any(
        (p) => p.providerId == 'password',
      ) ==
      true;
  String? get email => _service.currentUser?.email;

  Future<bool> checkVerification() => _guard(() async {
    if (!await _service.checkEmailVerification()) {
      error.value = _service.lastError;
      return false;
    }
    _session.markAuthenticated();
    return true;
  });

  Future<bool> resendVerification() => _guard(() async {
    if (!await _service.resendVerificationEmail()) {
      error.value = _service.lastError;
      return false;
    }
    return true;
  });

  Future<bool> deleteAccount({String? password}) => _guard(() async {
    if (!await _service.reauthenticate(password: password)) {
      error.value = _service.lastError;
      return false;
    }
    if (!Get.isRegistered<GatewayCloudDataSource>()) {
      error.value = 'Account data service is unavailable.';
      return false;
    }
    await Get.find<GatewayCloudDataSource>().deleteAccountData();
    await _session.clearLocalGateways();
    if (!await _service.deleteCurrentUser()) {
      error.value = _service.lastError;
      return false;
    }
    _session.markLogin();
    return true;
  });

  Future<void> signOut() => _session.signOut();

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
