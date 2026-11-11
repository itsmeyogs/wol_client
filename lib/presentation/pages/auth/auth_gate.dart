import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/auth/auth_mode.dart';
import '../../controllers/auth_controller.dart';
import '../gateway/gateway_list_page.dart';
import 'login_page.dart';

class AuthGate extends GetView<AuthController> {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    switch (controller.mode.value) {
      case AuthMode.guest:
      case AuthMode.authenticated:
        return const GatewayListPage();
      case AuthMode.login:
        return const LoginPage();
      case AuthMode.unavailable:
        return _UnavailableAuth(error: controller.error.value);
      case AuthMode.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  });
}

class _UnavailableAuth extends GetView<AuthController> {
  const _UnavailableAuth({required this.error});
  final String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Authentication unavailable'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: controller.restoreSession,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
  );
}
