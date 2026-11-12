import 'package:get/get.dart';
import '../../core/auth/auth_mode.dart';
import '../../core/errors/gateway_failure.dart';
import '../../core/network/gateway_url.dart';
import '../../data/models/gateway.dart';
import '../../domain/usecases/gateway_usecases.dart';
import '../../domain/usecases/gateway_sync_usecase.dart';
import '../../core/logging/app_logger.dart';
import '../../core/ui/app_snackbar.dart';
import 'auth_controller.dart';

class GatewayController extends GetxController {
  GatewayController(
    this._getGateways,
    this._saveGateway,
    this._deleteGateway, [
    SyncGateways? syncGateways,
    ClearLocalGateways? clearLocalGateways,
  ]) : _syncGateways = syncGateways,
       _clearLocalGateways = clearLocalGateways;
  final GetGateways _getGateways;
  final SaveGateway _saveGateway;
  final DeleteGateway _deleteGateway;
  final SyncGateways? _syncGateways;
  final ClearLocalGateways? _clearLocalGateways;
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
      error.value = 'Local gateways could not be loaded.';
      AppSnackbar.error(error.value!);
    } finally {
      isLoading.value = false;
    }
  }

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
    await _syncLocalChange();
  }

  Future<void> deleteGateway(Gateway gateway) async {
    if (gateway.id == null) return;
    await _deleteGateway(gateway.id!);
    await load();
    await _syncLocalChange();
  }

  Future<void> clearLocalState() async {
    await _clearLocalGateways?.call();
    gateways.clear();
    error.value = null;
  }

  Future<void> _syncLocalChange() async {
    if (!Get.isRegistered<AuthController>() ||
        Get.find<AuthController>().mode.value != AuthMode.authenticated) {
      return;
    }
    try {
      await _syncGateways?.call();
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
