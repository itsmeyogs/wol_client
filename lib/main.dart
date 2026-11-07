import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/database/database_factory.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bindings/app_binding.dart';
import 'presentation/pages/gateway_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDatabaseFactory();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'WoL Client',
    theme: AppTheme.light,
    initialBinding: AppBinding(),
    home: const GatewayListPage(),
  );
}
