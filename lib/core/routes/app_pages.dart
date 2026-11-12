import 'package:get/get.dart';

import '../../presentation/pages/auth/auth_gate.dart';
import '../../presentation/pages/auth/email_verification_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/device/device_add_edit_page.dart';
import '../../presentation/pages/device/device_detail_page.dart';
import '../../presentation/pages/device/discovery_scan_page.dart';
import '../../presentation/pages/diagnostics/diagnostics_page.dart';
import '../../presentation/pages/gateway/gateway_dashboard_page.dart';
import '../../presentation/pages/gateway/gateway_form_page.dart';
import '../../presentation/pages/gateway/gateway_list_page.dart';
import '../../presentation/pages/settings/settings_email_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/settings/settings_password_page.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.root, page: () => const AuthGate()),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(name: AppRoutes.register, page: () => const RegisterPage()),
    GetPage(
      name: AppRoutes.verifyEmail,
      page: () => const EmailVerificationPage(),
    ),
    GetPage(name: AppRoutes.gateways, page: () => const GatewayListPage()),
    GetPage(name: AppRoutes.gatewayForm, page: () => const GatewayFormPage()),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const GatewayDashboardPage(),
    ),
    GetPage(name: AppRoutes.discovery, page: () => const DiscoveryScanPage()),
    GetPage(name: AppRoutes.deviceForm, page: () => const DeviceAddEditPage()),
    GetPage(name: AppRoutes.deviceDetail, page: () => const DeviceDetailPage()),
    GetPage(name: AppRoutes.diagnostics, page: () => const DiagnosticsPage()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsPage()),
    GetPage(
      name: AppRoutes.settingsEmail,
      page: () => const SettingsEmailPage(),
    ),
    GetPage(
      name: AppRoutes.settingsPassword,
      page: () => const SettingsPasswordPage(),
    ),
  ];
}
