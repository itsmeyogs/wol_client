import 'package:get/get.dart';
import '../../core/errors/gateway_failure.dart';
import '../../data/models/device.dart';
import '../../domain/usecases/device_usecases.dart';
import 'gateway_session_controller.dart';
import '../../core/logging/app_logger.dart';
import '../../core/ui/app_snackbar.dart';

class DeviceController extends GetxController {
  DeviceController(
    this._getDevices,
    this._getDevice,
    this._saveDevice,
    this._deleteDevice,
    this._discoverDevices,
    this._checkDeviceStatus,
    this._wakeDevice,
    this._session,
  );
  final GetDevices _getDevices;
  final GetDevice _getDevice;
  final SaveDevice _saveDevice;
  final DeleteDevice _deleteDevice;
  final DiscoverDevices _discoverDevices;
  final CheckDeviceStatus _checkDeviceStatus;
  final WakeDevice _wakeDevice;
  final GatewaySessionController _session;
  final devices = <Device>[].obs;
  final discovered = <DiscoveryDevice>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isDiscovering = false.obs;
  final error = RxnString();
  final discoveryError = RxnString();
  final statusResults = <int, DeviceStatusResult>{}.obs;
  final wakeResults = <int, DeviceWakeResult>{}.obs;
  final statusLoadingIds = <int>{}.obs;
  final wakeLoadingIds = <int>{}.obs;

  Future<void> load() async {
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

  Future<Device> loadDevice(int id) async {
    final gateway = _session.activeGateway.value;
    if (gateway == null) throw const GatewayFailure('No gateway is selected.');
    try {
      return await _getDevice(gateway, id);
    } on GatewayFailure {
      rethrow;
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Device detail load failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      AppSnackbar.error('Device details could not be loaded.');
      throw const GatewayFailure('Device details could not be loaded.');
    }
  }

  Future<void> saveDevice({
    int? id,
    required String name,
    required String ipAddress,
    required String macAddress,
    required String broadcastAddress,
    required String wolPort,
    required String statusCheckMethod,
    required String statusCheckPort,
  }) async {
    final gateway = _session.activeGateway.value;
    if (gateway == null) throw const GatewayFailure('No gateway is selected.');
    final cleanName = name.trim();
    final cleanIp = ipAddress.trim();
    final cleanMac = macAddress.trim().toUpperCase();
    final cleanBroadcast = broadcastAddress.trim();
    if (cleanName.isEmpty) {
      throw const GatewayFailure('Device name is required.');
    }
    if (!_validIpv4(cleanIp)) {
      throw const GatewayFailure('Enter a valid IPv4 address.');
    }
    if (!_validMac(cleanMac)) {
      throw const GatewayFailure('Enter a valid MAC address.');
    }
    if (!_validIpv4(cleanBroadcast)) {
      throw const GatewayFailure('Enter a valid broadcast address.');
    }
    final parsedWolPort = int.tryParse(wolPort);
    final parsedStatusPort = int.tryParse(statusCheckPort);
    if (!_validPort(parsedWolPort) || !_validPort(parsedStatusPort)) {
      throw const GatewayFailure('Ports must be between 1 and 65535.');
    }
    isSaving.value = true;
    try {
      await _saveDevice(
        gateway,
        Device(
          id: id,
          name: cleanName,
          ipAddress: cleanIp,
          macAddress: cleanMac,
          broadcastAddress: cleanBroadcast,
          wolPort: parsedWolPort!,
          statusCheckMethod: statusCheckMethod,
          statusCheckPort: parsedStatusPort!,
        ),
      );
      await load();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteDevice(Device device) async {
    final gateway = _session.activeGateway.value;
    if (gateway == null || device.id == null) return;
    await _deleteDevice(gateway, device.id!);
    await load();
  }

  Future<void> discover() async {
    final gateway = _session.activeGateway.value;
    if (gateway == null) return;
    isDiscovering.value = true;
    discoveryError.value = null;
    discovered.clear();
    try {
      discovered.assignAll(await _discoverDevices(gateway));
    } on GatewayFailure catch (failure) {
      discoveryError.value = failure.message;
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Device discovery failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      discoveryError.value = 'Device discovery failed.';
      AppSnackbar.error(discoveryError.value!);
    } finally {
      isDiscovering.value = false;
    }
  }

  Future<DeviceStatusResult> checkStatus(Device device) async {
    final id = device.id;
    if (id == null) throw const GatewayFailure('Device ID is missing.');
    if (statusLoadingIds.contains(id)) {
      throw const GatewayFailure('Status check is already running.');
    }
    final gateway = _session.activeGateway.value;
    if (gateway == null) throw const GatewayFailure('No gateway is selected.');
    statusLoadingIds.add(id);
    try {
      final result = await _checkDeviceStatus(gateway, id);
      statusResults[id] = result;
      final index = devices.indexWhere((item) => item.id == id);
      if (index != -1) {
        devices[index] = devices[index].copyWith(
          status: result.status,
          lastCheckAt: result.checkedAt,
          lastCheckLatencyMs: result.latencyMs,
          lastCheckReason: result.reason,
        );
      }
      return result;
    } finally {
      statusLoadingIds.remove(id);
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
      wakeResults[id] = result;
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

  bool _validPort(int? value) => value != null && value >= 1 && value <= 65535;
  bool _validMac(String value) =>
      RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$').hasMatch(value);
  bool _validIpv4(String value) {
    final parts = value.split('.');
    return parts.length == 4 &&
        parts.every((part) {
          final number = int.tryParse(part);
          return number != null &&
              number >= 0 &&
              number <= 255 &&
              (part == '0' || !part.startsWith('0'));
        });
  }
}
