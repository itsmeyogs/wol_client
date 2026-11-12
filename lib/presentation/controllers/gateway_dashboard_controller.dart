import 'package:get/get.dart';

import '../../core/errors/gateway_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/ui/app_snackbar.dart';
import '../../data/models/device.dart';
import '../../domain/usecases/device_usecases.dart';
import 'gateway_session_controller.dart';

/// Owns the gateway dashboard device list.
class GatewayDashboardController extends GetxController {
  GatewayDashboardController(
    this._getDevices,
    this._wakeDevice,
    this._session,
  );

  final GetDevices _getDevices;
  final WakeDevice _wakeDevice;
  final GatewaySessionController _session;

  final devices = <Device>[].obs;
  final isLoading = false.obs;
  final error = RxnString();
  final wakeLoadingIds = <int>{}.obs;

  Future<void> load() async {
    if (isLoading.value) return;
    final gateway = _session.activeGateway.value;
    if (gateway == null) return;
    isLoading.value = true;
    error.value = null;
    try {
      devices.assignAll(await _getDevices(gateway));
    } on GatewayFailure catch (failure) {
      error.value = failure.message;
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Device list load failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      error.value = 'Devices could not be loaded.';
      AppSnackbar.error(error.value!);
    } finally {
      isLoading.value = false;
    }
  }

  Future<DeviceWakeResult> wake(Device device) async {
    final id = device.id;
    if (id == null) throw const GatewayFailure('Device ID is missing.');
    if (wakeLoadingIds.contains(id)) {
      throw const GatewayFailure('Wake action is already running.');
    }
    final gateway = _session.activeGateway.value;
    if (gateway == null) throw const GatewayFailure('No gateway is selected.');
    wakeLoadingIds.add(id);
    try {
      final result = await _wakeDevice(gateway, id);
      final index = devices.indexWhere((item) => item.id == id);
      if (index != -1) {
        devices[index] = devices[index].copyWith(
          lastWolResult: result.result,
          lastWolAt: DateTime.now(),
        );
      }
      return result;
    } finally {
      wakeLoadingIds.remove(id);
    }
  }
}
