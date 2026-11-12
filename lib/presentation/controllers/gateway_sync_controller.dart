import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import '../../core/logging/app_logger.dart';
import '../../core/ui/app_snackbar.dart';
import '../../domain/usecases/gateway_sync_usecase.dart';
import 'gateway_list_controller.dart';

class GatewaySyncController extends GetxController {
  GatewaySyncController(this._syncGateways);
  final SyncGateways _syncGateways;
  final isSyncing = false.obs;
  final error = RxnString();
  bool _queued = false;
  Future<void>? _active;

  /// Push/pull used after a local gateway change.
  Future<void> runSync() => sync(silent: true);

  /// Pulls the cloud copy, then reloads the local list.
  ///
  /// A concurrent call joins the running sync instead of silently no-oping, so
  /// a user-initiated refresh always ends with fresh data.
  Future<void> sync({bool silent = false}) {
    final active = _active;
    if (active != null) {
      _queued = true;
      return active;
    }
    final future = _execute(firstSilent: silent);
    _active = future;
    return future;
  }

  Future<void> _execute({required bool firstSilent}) async {
    var silent = firstSilent;
    try {
      do {
        _queued = false;
        isSyncing.value = true;
        error.value = null;
        try {
          await _syncGateways();
          if (Get.isRegistered<GatewayListController>()) {
            await Get.find<GatewayListController>().load();
          }
        } catch (exception, stackTrace) {
          final detail = _describe(exception);
          AppLogger.instance.error(
            'Firebase gateway sync failed: ${exception.runtimeType}$detail',
            exception,
            stackTrace,
          );
          error.value = _userMessage(exception, detail);
          if (!silent) AppSnackbar.error(error.value!);
        } finally {
          isSyncing.value = false;
        }
        // A queued retry stays quiet; the first failure was already reported.
        silent = true;
      } while (_queued);
    } finally {
      _queued = false;
      _active = null;
    }
  }

  /// Safe, token-free error detail for logs.
  static String _describe(Object exception) {
    if (exception is FirebaseException) {
      return ' [${exception.plugin}/${exception.code}] ${exception.message}';
    }
    if (exception is StateError) return ' [state] ${exception.message}';
    return '';
  }

  static String _userMessage(Object exception, String detail) {
    if (exception is FirebaseException) {
      return switch (exception.code) {
        'permission-denied' => 'Cloud sync is not allowed for this account.',
        'unauthenticated' => 'Sign in again to sync gateway data.',
        'unavailable' || 'deadline-exceeded' =>
          'Cloud sync is unreachable. Check your connection.',
        'failed-precondition' =>
          'Cloud sync is not ready. Enable Firestore in Firebase Console.',
        'not-found' =>
          'Cloud database is missing. Check the Firebase project setup.',
        _ => 'Gateway sync could not be completed (${exception.code}).',
      };
    }
    if (exception is StateError) return exception.message;
    return 'Gateway sync could not be completed.$detail';
  }
}
