import 'package:get/get.dart';

import '../../core/errors/gateway_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/gateway.dart';
import 'gateway_list_controller.dart';

/// Owns the add/edit gateway form.
class GatewayFormController extends GetxController {
  GatewayFormController(this.gateway);

  final Gateway? gateway;
  final isSaving = false.obs;
  final error = RxnString();
  bool get isEdit => gateway != null;

  Future<bool> save({
    required String name,
    required String scheme,
    required String baseUrl,
    required String apiToken,
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    error.value = null;
    try {
      await Get.find<GatewayListController>().saveGateway(
        id: gateway?.id,
        name: name,
        scheme: scheme,
        baseUrl: baseUrl,
        apiToken: apiToken,
        createdAt: gateway?.createdAt,
      );
      return true;
    } on GatewayFailure catch (failure) {
      error.value = failure.message;
      return false;
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Gateway save failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      error.value = 'Gateway could not be saved.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
