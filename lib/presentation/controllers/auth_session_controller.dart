import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../core/auth/auth_mode.dart';
import '../../core/auth/auth_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/ui/app_snackbar.dart';
import 'gateway_list_controller.dart';
import 'gateway_sync_controller.dart';

/// Global authentication session shared by every page.
class AuthSessionController extends GetxController {
  AuthSessionController(this.service);

  final AuthService service;
  final mode = AuthMode.loading.obs;
  final error = RxnString();

  User? get currentUser => service.currentUser;
  bool get needsEmailVerification =>
      service.needsEmailVerification(currentUser);
  bool get canSetPassword => service.canSetPassword;
  bool get needsGoogleLinkPassword => service.needsGoogleLinkPassword;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  Future<void> restoreSession() async {
    try {
      final guest = (await service.preferences).getBool(AuthService.guestKey) ==
          true;
      if (!service.available) {
        error.value =
            'Firebase is unavailable. Check the local configuration.';
        mode.value = guest ? AuthMode.guest : AuthMode.login;
        return;
      }
      final user = service.currentUser;
      if (user != null) {
        await user.reload();
        if (needsEmailVerification) {
          mode.value = AuthMode.verification;
          return;
        }
        mode.value = AuthMode.authenticated;
        syncGateways();
      } else if (guest) {
        mode.value = AuthMode.guest;
      } else {
        mode.value = AuthMode.login;
      }
    } on FirebaseAuthException catch (exception) {
      AppLogger.instance.error(
        'Firebase auth restore failed: code=${exception.code}',
        exception,
        exception.stackTrace,
      );
      error.value = AuthService.message(exception);
      AppSnackbar.error(error.value!);
      mode.value = AuthMode.unavailable;
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Firebase auth restore failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      error.value = 'Authentication could not be initialized.';
      AppSnackbar.error(error.value!);
      mode.value = AuthMode.unavailable;
    }
  }

  Future<void> continueAsGuest() async {
    error.value = null;
    await (await service.preferences).setBool(AuthService.guestKey, true);
    mode.value = AuthMode.guest;
  }

  void markAuthenticated() {
    mode.value = AuthMode.authenticated;
    syncGateways();
  }

  void markLogin() => mode.value = AuthMode.login;

  void markVerification() => mode.value = AuthMode.verification;

  Future<void> signOut() async {
    await clearLocalGateways();
    await service.signOut();
    mode.value = AuthMode.login;
  }

  Future<void> signOutUnverified() async {
    await service.signOutUnverified();
    error.value = null;
    mode.value = AuthMode.login;
  }

  Future<void> clearLocalGateways() async {
    if (!Get.isRegistered<GatewayListController>()) return;
    await Get.find<GatewayListController>().clearLocalState();
  }

  void syncGateways({bool silent = true}) {
    if (service.currentUser == null) return;
    if (!Get.isRegistered<GatewaySyncController>()) {
      AppLogger.instance.debug('Gateway sync is unavailable for this session');
      return;
    }
    Get.find<GatewaySyncController>().sync(silent: silent);
  }
}
