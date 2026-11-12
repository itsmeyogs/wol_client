import 'package:get/get.dart';

import '../../core/errors/gateway_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/device.dart';
import '../../domain/usecases/device_usecases.dart';
import 'gateway_session_controller.dart';

/// Owns the add/edit device form.
class DeviceAddEditController extends GetxController {
  DeviceAddEditController(this._saveDevice, this._session);

  final SaveDevice _saveDevice;
  final GatewaySessionController _session;

  final isSaving = false.obs;
  final error = RxnString();

  Future<bool> save({
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
    if (gateway == null) {
      throw const GatewayFailure('No gateway is selected.');
    }
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
    if (isSaving.value) return false;
    isSaving.value = true;
    error.value = null;
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
      return true;
    } catch (exception, stackTrace) {
      if (exception is GatewayFailure) {
        error.value = exception.message;
      } else {
        AppLogger.instance.error(
          'Device save failed: ${exception.runtimeType}',
          exception,
          stackTrace,
        );
        error.value = 'Device could not be saved.';
      }
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  static bool _validPort(int? value) =>
      value != null && value >= 1 && value <= 65535;
  static bool _validMac(String value) =>
      RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$').hasMatch(value);
  static bool _validIpv4(String value) {
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
