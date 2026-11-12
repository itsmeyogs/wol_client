import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/ui/app_snackbar.dart';
import '../../controllers/auth_controller.dart';
import '../gateway/gateway_list_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  AuthController get controller => Get.find<AuthController>();

  Future<void> _signInEmail() async {
    if (await controller.signInEmail(email.text, password.text)) {
      AppSnackbar.success('Login berhasil.');
      Get.offAll(() => const GatewayListPage());
    } else if (controller.error.value != null) {
      AppSnackbar.error(controller.error.value!);
    }
  }

  Future<void> _signInGoogle() async {
    if (await controller.signInGoogle()) {
      AppSnackbar.success('Login Google berhasil.');
      Get.offAll(() => const GatewayListPage());
    } else if (controller.needsGoogleLinkPassword) {
      await _completeGoogleLink();
    } else if (controller.error.value != null) {
      AppSnackbar.error(controller.error.value!);
    }
  }

  Future<void> _completeGoogleLink() async {
    password.clear();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm your account'),
        content: TextField(
          controller: password,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email account password',
          ),
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    if (await controller.completeGoogleLink(password.text)) {
      AppSnackbar.success(
        'Google linked. You can now sign in with either method.',
      );
      Get.offAll(() => const GatewayListPage());
    } else if (controller.error.value != null) {
      AppSnackbar.error(controller.error.value!);
    }
  }

  Future<void> _continueAsGuest() async {
    await controller.continueAsGuest();
    Get.offAll(() => const GatewayListPage());
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Obx(() {
              final busy = controller.isBusy.value;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.power_settings_new, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'WoL Client',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    enabled: !busy,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : _signInEmail,
                    child: const Text('Sign in'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy ? null : _signInGoogle,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: busy ? null : _continueAsGuest,
                    child: const Text('Continue as Guest'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => Get.to(() => const RegisterPage()),
                    child: const Text('Create an account'),
                  ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
