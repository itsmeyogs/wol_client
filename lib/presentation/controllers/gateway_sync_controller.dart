import 'package:get/get.dart';

import '../../domain/usecases/gateway_sync_usecase.dart';
import 'gateway_controller.dart';
import '../../core/logging/app_logger.dart';
import '../../core/ui/app_snackbar.dart';

class GatewaySyncController extends GetxController {
  GatewaySyncController(this._syncGateways);
  final SyncGateways _syncGateways;
  final isSyncing = false.obs;
  final error = RxnString();
  bool _queued = false;

  Future<void> sync({bool silent = false}) async {
    if (isSyncing.value) {
      _queued = true;
      return;
    }
    isSyncing.value = true;
    error.value = null;
    try {
      await _syncGateways();
      if (Get.isRegistered<GatewayController>()) {
        await Get.find<GatewayController>().load();
      }
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Firebase gateway sync failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      error.value = 'Gateway sync could not be completed.';
      AppSnackbar.error(error.value!);
    } finally {
      isSyncing.value = false;
      if (_queued) {
        _queued = false;
        await sync(silent: true);
      }
    }
  }
}
