import 'package:get/get.dart';

import '../../core/errors/gateway_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/ui/app_snackbar.dart';
import '../../data/models/device.dart';
import '../../domain/usecases/device_usecases.dart';
import 'gateway_session_controller.dart';

/// Owns the LAN discovery scan screen.
class DiscoveryScanController extends GetxController {
  DiscoveryScanController(this._discoverDevices, this._session);

  final DiscoverDevices _discoverDevices;
  final GatewaySessionController _session;

  final discovered = <DiscoveryDevice>[].obs;
  final isDiscovering = false.obs;
  final discoveryError = RxnString();

  Future<void> discover() async {
    if (isDiscovering.value) return;
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
}
