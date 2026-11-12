import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/auth/auth_mode.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_page.dart';
import 'settings_password_page.dart';

class SettingsPage extends GetView<AuthController> {
  const SettingsPage({super.key});

  Future<void> _signUp(BuildContext context) async {
    final email = TextEditingController();
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final key = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create account'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: email,
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
                TextFormField(
                  controller: password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value == null || value.length < 6
                      ? 'Use at least 6 characters.'
                      : null,
                ),
                TextFormField(
                  controller: confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  validator: (value) =>
                      value != password.text ? 'Passwords do not match.' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Create account'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      final created = await controller.registerEmailFromSettings(
        email.text,
        password.text,
      );
      if (created) {
        AppSnackbar.success(
          'Verification email sent. Your account is signed in.',
        );
      } else if (controller.error.value != null) {
        AppSnackbar.error(controller.error.value!);
      }
    }
    email.dispose();
    password.dispose();
    confirmation.dispose();
  }

  Future<void> _googleSignIn() async {
    if (await controller.signInGoogle()) {
      AppSnackbar.success('Google sign-in complete.');
    } else if (controller.error.value != null) {
      AppSnackbar.error(controller.error.value!);
    }
  }

  Future<void> _verificationAction() async {
    final user = controller.currentUser;
    if (user == null) return;
    if (await controller.checkEmailVerification()) {
      AppSnackbar.success('Email verified.');
      return;
    }
    if (!user.emailVerified) {
      if (await controller.resendVerificationEmail()) {
        AppSnackbar.success('Verification email sent.');
      } else if (controller.error.value != null) {
        AppSnackbar.error(controller.error.value!);
      }
    } else if (controller.error.value != null) {
      AppSnackbar.error(controller.error.value!);
    }
  }

  Future<void> _signOut() async {
    await controller.signOut();
    Get.offAll(() => const LoginPage());
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final password = TextEditingController();
    final hasPassword =
        controller.currentUser?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ==
        true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your Firebase account and all synced and local gateways. This cannot be undone.',
            ),
            if (hasPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final deleted = await controller.deleteAccount(
        password: hasPassword ? password.text : null,
      );
      if (deleted) {
        AppSnackbar.success('Account and its data deleted.');
        Get.offAll(() => const LoginPage());
      } else if (controller.error.value != null) {
        AppSnackbar.error(controller.error.value!);
      }
    }
    password.dispose();
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String description,
    required Widget content,
    required bool wide,
  }) {
    final theme = Theme.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
    final panel = Card(
      child: Padding(padding: const EdgeInsets.all(20), child: content),
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [heading, const SizedBox(height: 14), panel],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 230,
          child: Padding(
            padding: const EdgeInsets.only(top: 14, right: 24),
            child: heading,
          ),
        ),
        Expanded(child: panel),
      ],
    );
  }

  Widget _accountLine(BuildContext context, String value) => Row(
    children: [
      Icon(
        Icons.person_outline,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signed in as',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            SelectableText(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: Obx(() {
      final mode = controller.mode.value;
      final user = controller.currentUser;
      final guest = mode == AuthMode.guest;
      final unverified = controller.needsEmailVerification;
      final wide = MediaQuery.sizeOf(context).width >= 760;
      final theme = Theme.of(context);
      final accountActions = <Widget>[];
      if (guest) {
        accountActions.addAll([
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: controller.isBusy.value ? null : _googleSignIn,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Continue with Google'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: controller.isBusy.value
                  ? null
                  : () => _signUp(context),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Create account with email'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => Get.to(() => const LoginPage()),
              child: const Text('Sign in to an existing account'),
            ),
          ),
        ]);
      } else if (unverified) {
        accountActions.add(
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: controller.isBusy.value ? null : _verificationAction,
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: const Text('Verify email'),
            ),
          ),
        );
      }
      final hasPassword =
          user?.providerData.any((p) => p.providerId == 'password') == true;
      final securityAction =
          user != null &&
              !unverified &&
              (controller.canSetPassword || hasPassword)
          ? SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Get.to(
                  () => SettingsPasswordPage(
                    setPassword: controller.canSetPassword,
                  ),
                ),
                icon: const Icon(Icons.lock_outline),
                label: Text(
                  controller.canSetPassword
                      ? 'Set password'
                      : 'Change password',
                ),
              ),
            )
          : Text(
              unverified
                  ? 'Verify your email to manage sign-in security.'
                  : 'Password sign-in is not enabled for this account.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
      return LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 32 : 20,
            vertical: 28,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Settings',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your account and sign-in methods.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _section(
                      context,
                      title: 'Account',
                      description: 'Your current account for gateway sync.',
                      wide: wide,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _accountLine(
                            context,
                            guest ? 'Guest' : user?.email ?? '—',
                          ),
                          if (accountActions.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            ...accountActions,
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      context,
                      title: 'Sign-in & security',
                      description:
                          'Manage the password linked to this account.',
                      wide: wide,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [securityAction],
                      ),
                    ),
                    if (!guest && user != null) ...[
                      const SizedBox(height: 24),
                      _section(
                        context,
                        title: 'Session',
                        description: 'End this session on this device.',
                        wide: wide,
                        content: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: controller.isBusy.value
                                ? null
                                : _signOut,
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign out'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _section(
                        context,
                        title: 'Delete account',
                        description:
                            'Permanently remove this account and its data.',
                        wide: wide,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All synced gateways, local gateways on this device, and the Firebase account will be deleted.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              onPressed: controller.isBusy.value
                                  ? null
                                  : () => _deleteAccount(context),
                              icon: const Icon(Icons.delete_forever_outlined),
                              label: const Text('Delete account permanently'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (controller.isBusy.value) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }),
  );
}
