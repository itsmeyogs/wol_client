import 'package:get/get.dart';

import '../../core/errors/gateway_failure.dart';
import '../../data/models/gateway_diagnostics.dart';
import '../../domain/usecases/diagnostics_usecases.dart';
import 'gateway_session_controller.dart';

class DiagnosticsController extends GetxController {
  DiagnosticsController(this._getDiagnostics, this._session);

  final GetDiagnostics _getDiagnostics;
  final GatewaySessionController _session;
  final diagnostics = Rxn<GatewayDiagnostics>();
  final isLoading = false.obs;
  final error = RxnString();

  Future<void> load() async {
    if (isLoading.value) return;
    final gateway = _session.activeGateway.value;
    if (gateway == null) {
      error.value = 'No gateway is selected.';
      return;
    }
    isLoading.value = true;
    error.value = null;
    try {
      diagnostics.value = await _getDiagnostics(gateway);
    } on GatewayFailure catch (failure) {
      error.value = failure.message;
    } catch (_) {
      error.value = 'Diagnostics could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }
}
