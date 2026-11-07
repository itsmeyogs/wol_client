import 'package:get/get.dart';
import '../../core/errors/gateway_failure.dart';
import '../../core/network/gateway_url.dart';
import '../../data/models/gateway.dart';
import '../../domain/usecases/gateway_usecases.dart';

class GatewayController extends GetxController {
  GatewayController(this._getGateways, this._saveGateway, this._deleteGateway);
  final GetGateways _getGateways;
  final SaveGateway _saveGateway;
  final DeleteGateway _deleteGateway;
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
    } catch (_) {
      error.value = 'Local gateways could not be loaded.';
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
  }

  Future<void> deleteGateway(Gateway gateway) async {
    if (gateway.id == null) return;
    await _deleteGateway(gateway.id!);
    await load();
  }
}
