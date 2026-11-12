import 'package:get/get.dart';

import '../../core/auth/auth_mode.dart';
import '../../core/errors/gateway_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/gateway_url.dart';
import '../../core/ui/app_snackbar.dart';
import '../../data/models/gateway.dart';
import '../../domain/usecases/gateway_usecases.dart';
import 'auth_session_controller.dart';
import 'gateway_session_controller.dart';
import 'gateway_sync_controller.dart';

/// Owns the gateway list screen: loading, deleting, and the mutation API used
/// by [GatewayFormController].
class GatewayListController extends GetxController {
  GatewayListController(
    this._getGateways,
    this._saveGateway,
    this._deleteGateway,
    this._clearLocalGateways, [
    this._session,
  ]);

  final GetGateways _getGateways;
  final SaveGateway _saveGateway;
  final DeleteGateway _deleteGateway;
  final ClearLocalGateways _clearLocalGateways;
  final AuthSessionController? _session;

  final gateways = <Gateway>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      gateways.assignAll(await _getGateways());
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Local gateway load failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      error.value = 'Local gateways could not be loaded. ${_detail(exception)}';
      AppSnackbar.error('Local gateways could not be loaded.');
    } finally {
      isLoading.value = false;
    }
  }

  /// User-initiated refresh: pull the cloud copy when signed in, otherwise
  /// just re-read the local database (guest mode has no cloud data).
  Future<void> refresh() async {
    final session = _session;
    if (session != null &&
        session.mode.value == AuthMode.authenticated &&
        Get.isRegistered<GatewaySyncController>()) {
      await Get.find<GatewaySyncController>().sync();
      return;
    }
    await load();
  }

  static String _detail(Object exception) =>
      exception.toString().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// True while the local list or a cloud refresh is in flight.
  bool get isRefreshing =>
      isLoading.value ||
      (Get.isRegistered<GatewaySyncController>() &&
          Get.find<GatewaySyncController>().isSyncing.value);

  Future<void> saveGateway({
    int? id,
    required String name,
    required String scheme,
    required String baseUrl,
    required String apiToken,
    DateTime? createdAt,
  }) async {
    final cleanName = name.trim();
    final cleanBaseUrl = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (cleanName.isEmpty) {
      throw const GatewayFailure(
        'Gateway name is required.',
        code: 'empty_name',
      );
    }
    if (apiToken.trim().isEmpty) {
      throw const GatewayFailure('API token is required.', code: 'empty_token');
    }
    GatewayUrl.validate(scheme, cleanBaseUrl);
    final now = DateTime.now();
    await _saveGateway(
      Gateway(
        id: id,
        name: cleanName,
        scheme: scheme,
        baseUrl: cleanBaseUrl,
        apiToken: apiToken.trim(),
        createdAt: createdAt ?? now,
        updatedAt: now,
      ),
    );
    await load();
    await syncLocalChange();
  }

  Future<void> deleteGateway(Gateway gateway) async {
    if (gateway.id == null) return;
    await _deleteGateway(gateway.id!);
    await load();
    await syncLocalChange();
  }

  void openGateway(Gateway gateway) {
    if (Get.isRegistered<GatewaySessionController>()) {
      Get.find<GatewaySessionController>().open(gateway);
    }
  }

  Future<void> clearLocalState() async {
    await _clearLocalGateways();
    gateways.clear();
    error.value = null;
  }

  Future<void> syncLocalChange() async {
    final session = _session;
    if (session == null || session.mode.value != AuthMode.authenticated) return;
    if (!Get.isRegistered<GatewaySyncController>()) return;
    try {
      await Get.find<GatewaySyncController>().runSync();
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Local gateway sync failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      // Local gateway changes remain usable and retry on the next sync.
    }
  }
}
