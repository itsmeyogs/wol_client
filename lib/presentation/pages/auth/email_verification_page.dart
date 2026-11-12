import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/ui/app_snackbar.dart';
import '../../controllers/auth_controller.dart';
import '../gateway/gateway_list_page.dart';
import 'login_page.dart';

class EmailVerificationPage extends GetView<AuthController> {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify your email')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Verify ${controller.currentUser?.email ?? 'your email'}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Open the verification link in your inbox, then check again here.',
                  textAlign: TextAlign.center,
                ),
                if (controller.error.value != null) ...[
                  const SizedBox(height: 12),
                  Text(controller.error.value!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: controller.isBusy.value
                      ? null
                      : () async {
                          if (await controller.checkEmailVerification()) {
                            Get.offAll(() => const GatewayListPage());
                          } else if (controller.error.value != null) {
                            AppSnackbar.error(controller.error.value!);
                          }
                        },
                  child: const Text('I verified — Check'),
                ),
                OutlinedButton(
                  onPressed: controller.isBusy.value
                      ? null
                      : () async {
                          final sent = await controller
                              .resendVerificationEmail();
                          if (sent)
                            AppSnackbar.success('Verification email sent.');
                          else if (controller.error.value != null)
                            AppSnackbar.error(controller.error.value!);
                        },
                  child: const Text('Send verification email again'),
                ),
                TextButton(
                  onPressed: controller.isBusy.value
                      ? null
                      : () async {
                          await controller.signOutUnverified();
                          Get.offAll(() => const LoginPage());
                        },
                  child: const Text('Log out and use another account'),
                ),
                if (controller.isBusy.value) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
