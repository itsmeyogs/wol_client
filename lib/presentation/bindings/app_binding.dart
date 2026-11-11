import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/database/app_database.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/gateway_local_data_source.dart';
import '../../data/repositories/gateway_repository_impl.dart';
import '../../domain/repositories/gateway_repository.dart';
import '../../domain/usecases/gateway_usecases.dart';
import '../controllers/gateway_controller.dart';
import '../controllers/gateway_session_controller.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/usecases/device_usecases.dart';
import '../controllers/device_controller.dart';
import '../../data/repositories/diagnostics_repository_impl.dart';
import '../../domain/repositories/diagnostics_repository.dart';
import '../../domain/usecases/diagnostics_usecases.dart';
import '../controllers/diagnostics_controller.dart';
import '../controllers/auth_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(
      AuthController(
        auth: Get.find<bool>(tag: 'firebaseReady')
            ? FirebaseAuth.instance
            : null,
      ),
      permanent: true,
    );
    Get.put<AppDatabase>(AppDatabase.instance, permanent: true);
    Get.put<DioClient>(DioClient.instance, permanent: true);
    Get.lazyPut<GatewayLocalDataSource>(
      () => GatewayLocalDataSource(database: Get.find<AppDatabase>()),
      fenix: true,
    );
    Get.lazyPut<GatewayRepository>(
      () => GatewayRepositoryImpl(
        local: Get.find<GatewayLocalDataSource>(),
        client: Get.find<DioClient>(),
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
    Get.lazyPut<DeviceRepository>(
      () => DeviceRepositoryImpl(client: Get.find<DioClient>()),
      fenix: true,
    );
    Get.lazyPut<GetDevices>(
      () => GetDevices(Get.find<DeviceRepository>()),
      fenix: true,
    );
    Get.lazyPut<GetDevice>(
      () => GetDevice(Get.find<DeviceRepository>()),
      fenix: true,
    );
    Get.lazyPut<SaveDevice>(
      () => SaveDevice(Get.find<DeviceRepository>()),
      fenix: true,
    );
    Get.lazyPut<DeleteDevice>(
      () => DeleteDevice(Get.find<DeviceRepository>()),
      fenix: true,
    );
    Get.lazyPut<DiscoverDevices>(
      () => DiscoverDevices(Get.find<DeviceRepository>()),
      fenix: true,
    );
    Get.lazyPut<CheckDeviceStatus>(
      () => CheckDeviceStatus(Get.find<DeviceRepository>()),
      fenix: true,
    );
    Get.lazyPut<WakeDevice>(
      () => WakeDevice(Get.find<DeviceRepository>()),
      fenix: true,
    );
    Get.lazyPut<DeviceController>(
      () => DeviceController(
        Get.find<GetDevices>(),
        Get.find<GetDevice>(),
        Get.find<SaveDevice>(),
        Get.find<DeleteDevice>(),
        Get.find<DiscoverDevices>(),
        Get.find<CheckDeviceStatus>(),
        Get.find<WakeDevice>(),
        Get.find<GatewaySessionController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<DiagnosticsRepository>(
      () => DiagnosticsRepositoryImpl(client: Get.find<DioClient>()),
      fenix: true,
    );
    Get.lazyPut<GetDiagnostics>(
      () => GetDiagnostics(Get.find<DiagnosticsRepository>()),
      fenix: true,
    );
    Get.lazyPut<DiagnosticsController>(
      () => DiagnosticsController(
        Get.find<GetDiagnostics>(),
        Get.find<GatewaySessionController>(),
      ),
      fenix: true,
    );
  }
}
