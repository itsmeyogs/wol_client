import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'core/database/database_factory.dart';
import 'core/logging/app_logger.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/url_strategy.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/bindings/app_binding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  FlutterError.onError = (details) {
    AppLogger.instance.error(
      'Unhandled Flutter error: ${details.exception.runtimeType}',
      details.exception,
      details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.instance.error(
      'Unhandled platform error: ${error.runtimeType}',
      error,
      stackTrace,
    );
    return true;
  };
  await configureDatabaseFactory();
  var firebaseReady = true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (exception, stackTrace) {
    AppLogger.instance.error(
      'Firebase initialization failed',
      exception,
      stackTrace,
    );
    firebaseReady = false;
  }
  Get.put<bool>(firebaseReady, tag: 'firebaseReady', permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'WoL Client',
    theme: AppTheme.light,
    initialBinding: AppBinding(),
    initialRoute: AppRoutes.root,
    getPages: AppPages.pages,
    debugShowCheckedModeBanner: false,
  );
}
