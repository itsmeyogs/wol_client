import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/auth/auth_service.dart';
import '../../core/database/app_database.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/gateway_local_data_source.dart';
import '../../data/repositories/gateway_repository_impl.dart';
import '../../domain/repositories/gateway_repository.dart';
import '../../domain/usecases/gateway_usecases.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/usecases/device_usecases.dart';
import '../../data/repositories/diagnostics_repository_impl.dart';
import '../../domain/repositories/diagnostics_repository.dart';
import '../../domain/usecases/diagnostics_usecases.dart';
import '../../data/datasources/gateway_cloud_data_source.dart';
import '../../data/repositories/gateway_sync_repository_impl.dart';
import '../../domain/repositories/gateway_sync_repository.dart';
import '../../domain/usecases/gateway_sync_usecase.dart';

import '../controllers/auth_session_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/register_controller.dart';
import '../controllers/email_verification_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/settings_email_controller.dart';
import '../controllers/settings_password_controller.dart';
import '../controllers/gateway_list_controller.dart';
import '../controllers/gateway_dashboard_controller.dart';
import '../controllers/gateway_session_controller.dart';
import '../controllers/gateway_sync_controller.dart';
import '../controllers/discovery_scan_controller.dart';
import '../controllers/device_add_edit_controller.dart';
import '../controllers/device_detail_controller.dart';
import '../controllers/diagnostics_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    final firebaseReady = Get.find<bool>(tag: 'firebaseReady');

    Get.put<AppDatabase>(AppDatabase.instance, permanent: true);
    Get.put<DioClient>(DioClient.instance, permanent: true);
    Get.put<AuthService>(
      AuthService(auth: firebaseReady ? FirebaseAuth.instance : null),
      permanent: true,
    );

    Get.lazyPut<GatewayLocalDataSource>(
      () => GatewayLocalDataSource(database: Get.find<AppDatabase>()),
      fenix: true,
    );

    if (firebaseReady) {
      Get.lazyPut<GatewayCloudDataSource>(
        () => GatewayCloudDataSource(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        ),
        fenix: true,
      );
      Get.lazyPut<GatewaySyncRepository>(
        () => GatewaySyncRepositoryImpl(
          local: Get.find<GatewayLocalDataSource>(),
          cloud: Get.find<GatewayCloudDataSource>(),
        ),
        fenix: true,
      );
      Get.lazyPut<SyncGateways>(
        () => SyncGateways(Get.find<GatewaySyncRepository>()),
        fenix: true,
      );
      Get.put<GatewaySyncController>(
        GatewaySyncController(Get.find<SyncGateways>()),
        permanent: true,
      );
    }

    // Session controllers.
    Get.put<GatewaySessionController>(
      GatewaySessionController(),
      permanent: true,
    );
    Get.put<AuthSessionController>(
      AuthSessionController(Get.find<AuthService>()),
      permanent: true,
    );

    // Gateway.
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
    Get.lazyPut<ClearLocalGateways>(
      () => ClearLocalGateways(Get.find<GatewayRepository>()),
      fenix: true,
    );
    Get.lazyPut<GatewayListController>(
      () => GatewayListController(
        Get.find<GetGateways>(),
        Get.find<SaveGateway>(),
        Get.find<DeleteGateway>(),
        Get.find<ClearLocalGateways>(),
        Get.find<AuthSessionController>(),
      ),
      fenix: true,
    );

    // Devices.
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
    Get.lazyPut<GatewayDashboardController>(
      () => GatewayDashboardController(
        Get.find<GetDevices>(),
        Get.find<WakeDevice>(),
        Get.find<GatewaySessionController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<DiscoveryScanController>(
      () => DiscoveryScanController(
        Get.find<DiscoverDevices>(),
        Get.find<GatewaySessionController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<DeviceAddEditController>(
      () => DeviceAddEditController(
        Get.find<SaveDevice>(),
        Get.find<GatewaySessionController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<DeviceDetailController>(
      () => DeviceDetailController(
        Get.find<GetDevice>(),
        Get.find<DeleteDevice>(),
        Get.find<CheckDeviceStatus>(),
        Get.find<WakeDevice>(),
        Get.find<GatewaySessionController>(),
      ),
      fenix: true,
    );

    // Diagnostics.
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

    // Auth pages.
    Get.lazyPut<LoginController>(
      () => LoginController(
        Get.find<AuthService>(),
        Get.find<AuthSessionController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<RegisterController>(
      () => RegisterController(
        Get.find<AuthService>(),
        Get.find<AuthSessionController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<EmailVerificationController>(
      () => EmailVerificationController(
        Get.find<AuthService>(),
        Get.find<AuthSessionController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        Get.find<AuthService>(),
        Get.find<AuthSessionController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<SettingsEmailController>(
      () => SettingsEmailController(
        Get.find<AuthService>(),
        Get.find<AuthSessionController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<SettingsPasswordController>(
      () => SettingsPasswordController(Get.find<AuthService>()),
      fenix: true,
    );
  }
}
