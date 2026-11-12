import 'package:get/get.dart';

import '../../core/errors/gateway_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/device.dart';
import '../../data/models/gateway.dart';
import '../../domain/usecases/device_usecases.dart';
import 'gateway_session_controller.dart';

/// Owns one device detail screen.
class DeviceDetailController extends GetxController {
  DeviceDetailController(
    this._getDevice,
    this._deleteDevice,
    this._checkDeviceStatus,
    this._wakeDevice,
    this._session,
  );

  final GetDevice _getDevice;
  final DeleteDevice _deleteDevice;
  final CheckDeviceStatus _checkDeviceStatus;
  final WakeDevice _wakeDevice;
  final GatewaySessionController _session;

  final device = Rxn<Device>();
  final isLoading = false.obs;
  final error = RxnString();
  final isCheckingStatus = false.obs;
  final isWaking = false.obs;

  Future<void> load(int id) async {
    isLoading.value = true;
    error.value = null;
    try {
      device.value = await _getDevice(_requireGateway(), id);
    } on GatewayFailure catch (failure) {
      error.value = failure.message;
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Device detail load failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      error.value = 'Device details could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<DeviceStatusResult> checkStatus() async {
    final current = device.value;
    final id = current?.id;
    if (current == null || id == null) {
      throw const GatewayFailure('Device ID is missing.');
    }
    if (isCheckingStatus.value) {
      throw const GatewayFailure('Status check is already running.');
    }
    isCheckingStatus.value = true;
    try {
      final result = await _checkDeviceStatus(_requireGateway(), id);
      device.value = current.copyWith(
        status: result.status,
        lastCheckAt: result.checkedAt,
        lastCheckLatencyMs: result.latencyMs,
        lastCheckReason: result.reason,
      );
      return result;
    } finally {
      isCheckingStatus.value = false;
    }
  }

  Future<DeviceWakeResult> wake() async {
    final current = device.value;
    final id = current?.id;
    if (current == null || id == null) {
      throw const GatewayFailure('Device ID is missing.');
    }
    if (isWaking.value) {
      throw const GatewayFailure('Wake action is already running.');
    }
    isWaking.value = true;
    try {
      final result = await _wakeDevice(_requireGateway(), id);
      device.value = current.copyWith(
        lastWolResult: result.result,
        lastWolAt: DateTime.now(),
      );
      return result;
    } finally {
      isWaking.value = false;
    }
  }

  Future<void> delete() async {
    final id = device.value?.id;
    if (id == null) return;
    await _deleteDevice(_requireGateway(), id);
  }

  Gateway _requireGateway() {
    final gateway = _session.activeGateway.value;
    if (gateway == null) throw const GatewayFailure('No gateway is selected.');
    return gateway;
  }
}
