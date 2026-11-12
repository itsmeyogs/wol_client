import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/ui/app_snackbar.dart';
import '../../controllers/auth_controller.dart';

class SettingsEmailPage extends StatefulWidget {
  const SettingsEmailPage({super.key, required this.createAccount});
  final bool createAccount;

  @override
  State<SettingsEmailPage> createState() => _SettingsEmailPageState();
}

class _SettingsEmailPageState extends State<SettingsEmailPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  AuthController get auth => Get.find<AuthController>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final success = widget.createAccount
        ? await auth.registerEmailFromSettings(_email.text, _password.text)
        : await auth.signInEmail(_email.text, _password.text);
    if (!mounted) return;
    if (!success) {
      if (auth.error.value != null) {
        AppSnackbar.error(auth.error.value!);
      }
      return;
    }
    if (widget.createAccount) {
      AppSnackbar.success(
        'Account created. Verification link sent to your email.',
      );
      Get.back();
    } else {
      AppSnackbar.success('Signed in successfully.');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.createAccount ? 'Create account with email' : 'Sign in',
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Obx(
          () => Form(
            key: _form,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _email,
                  enabled: !auth.isBusy.value,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value == null ||
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value.trim())
                      ? 'Enter a valid email address.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  enabled: !auth.isBusy.value,
                  obscureText: true,
                  autofillHints: [
                    widget.createAccount
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value == null || value.length < 6
                      ? 'Use at least 6 characters.'
                      : null,
                ),
                if (widget.createAccount) ...[
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
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: auth.isBusy.value ? null : _submit,
                  child: Text(
                    widget.createAccount ? 'Create account' : 'Sign in',
                  ),
                ),
                if (!widget.createAccount) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: auth.isBusy.value
                        ? null
                        : () async {
                            if (await auth.signInGoogle()) {
                              AppSnackbar.success('Google sign-in complete.');
                              Get.back();
                            } else if (auth.error.value != null) {
                              AppSnackbar.error(auth.error.value!);
                            }
                          },
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Sign in with Google'),
                  ),
                ],
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
