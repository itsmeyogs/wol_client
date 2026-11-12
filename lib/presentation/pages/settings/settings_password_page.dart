import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/ui/app_snackbar.dart';
import '../../controllers/auth_controller.dart';
import 'settings_page.dart';

class SettingsPasswordPage extends StatefulWidget {
  const SettingsPasswordPage({super.key, required this.setPassword});
  final bool setPassword;

  @override
  State<SettingsPasswordPage> createState() => _SettingsPasswordPageState();
}

class _SettingsPasswordPageState extends State<SettingsPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _currentPassword = TextEditingController();
  AuthController get auth => Get.find<AuthController>();

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    _currentPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = widget.setPassword
        ? await auth.linkEmailPassword(_password.text)
        : await auth.changeEmailPassword(_password.text, _currentPassword.text);
    if (success) {
      AppSnackbar.success(
        widget.setPassword ? 'Password set.' : 'Password changed.',
      );
      Get.off(() => const SettingsPage());
    } else if (auth.error.value != null) {
      AppSnackbar.error(auth.error.value!);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.setPassword ? 'Set password' : 'Change password'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Obx(
          () => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                if (!widget.setPassword) ...[
                  TextFormField(
                    controller: _currentPassword,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your current password.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (value) => value == null || value.length < 6
                      ? 'Use at least 6 characters.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  validator: (value) => value != _password.text
                      ? 'Passwords do not match.'
                      : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: auth.isBusy.value ? null : _submit,
                  child: Text(
                    widget.setPassword ? 'Set password' : 'Change password',
                  ),
                ),
                if (auth.isBusy.value) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
