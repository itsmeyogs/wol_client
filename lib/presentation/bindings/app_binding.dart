import 'package:get/get.dart';

import '../../core/database/app_database.dart';
import '../../data/datasources/gateway_local_data_source.dart';
import '../../data/repositories/gateway_repository_impl.dart';
import '../../domain/repositories/gateway_repository.dart';
import '../../domain/usecases/gateway_usecases.dart';
import '../controllers/gateway_controller.dart';
import '../controllers/gateway_session_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AppDatabase>(AppDatabase.instance, permanent: true);
    Get.lazyPut<GatewayLocalDataSource>(
      () => GatewayLocalDataSource(database: Get.find<AppDatabase>()),
      fenix: true,
    );
    Get.lazyPut<GatewayRepository>(
      () => GatewayRepositoryImpl(
        local: Get.find<GatewayLocalDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<GetGateways>(
      () => GetGateways(Get.find<GatewayRepository>()),
      fenix: true,
    );
    Get.lazyPut<SaveGateway>(
      () => SaveGateway(Get.find<GatewayRepository>()),
      fenix: true,
    );
    Get.lazyPut<DeleteGateway>(
      () => DeleteGateway(Get.find<GatewayRepository>()),
      fenix: true,
    );

    Get.put<GatewaySessionController>(
      GatewaySessionController(),
      permanent: true,
    );
    Get.lazyPut<GatewayController>(
      () => GatewayController(
        Get.find<GetGateways>(),
        Get.find<SaveGateway>(),
        Get.find<DeleteGateway>(),
      ),
      fenix: true,
    );
  }
}
