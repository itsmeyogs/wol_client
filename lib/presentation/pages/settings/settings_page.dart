import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  Future<void> _verificationAction() async {
    if (await controller.checkVerification()) {
      AppSnackbar.success('Email verified.');
      return;
    }
    if (await controller.resendVerification()) {
      AppSnackbar.success('Verification email sent.');
    } else if (controller.error.value != null) {
      AppSnackbar.error(controller.error.value!);
    }
  }

  Future<void> _signOut() async {
    await controller.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final password = TextEditingController();
    final hasPassword = controller.hasPassword;
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
        Get.offAllNamed(AppRoutes.login);
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
        if (description.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
    final panel = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: content,
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
      final guest = controller.isGuest;
      final email = controller.email;
      final unverified = controller.needsEmailVerification;
      final busy = controller.isBusy.value;
      final wide = MediaQuery.sizeOf(context).width >= 1024;
      final accountActions = <Widget>[];
      if (guest) {
        accountActions.addAll([
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () =>
                        Get.toNamed(AppRoutes.settingsEmail, arguments: false),
              icon: const Icon(Icons.login),
              label: const Text('Sign in an existing account'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: busy
                  ? null
                  : () => Get.toNamed(AppRoutes.settingsEmail, arguments: true),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Create account with email'),
            ),
          ),
        ]);
      } else if (unverified) {
        accountActions.add(
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: busy ? null : _verificationAction,
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: const Text('Verify email'),
            ),
          ),
        );
      }
      final securityAction =
          email != null &&
              !guest &&
              !unverified &&
              (controller.canSetPassword || controller.hasPassword)
          ? SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed(
                  AppRoutes.settingsPassword,
                  arguments: controller.canSetPassword,
                ),
                icon: const Icon(Icons.lock_outline),
                label: Text(
                  controller.canSetPassword
                      ? 'Set a password'
                      : 'Change password',
                ),
              ),
            )
          : null;
      final signedIn = !guest && email != null;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (signedIn)
            _section(
              context,
              title: 'Account',
              description: 'The account used to sync gateways across devices.',
              wide: wide,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _accountLine(context, email),
                  if (accountActions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...accountActions,
                  ],
                ],
              ),
            )
          else
            _section(
              context,
              title: 'Account',
              description:
                  'Sign in to sync gateways across devices. Guest mode stays local.',
              wide: wide,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: accountActions,
              ),
            ),
          if (signedIn) ...[
            const Divider(height: 32),
            _section(
              context,
              title: 'Security',
              description: 'Manage how you sign in to this account.',
              wide: wide,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?securityAction,
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            _section(
              context,
              title: 'Danger zone',
              description:
                  'Deleting the account removes cloud data and local gateways.',
              wide: wide,
              content: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: busy ? null : () => _deleteAccount(context),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Delete account'),
                ),
              ),
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (controller.error.value != null && !busy) ...[
            const SizedBox(height: 12),
            Text(
              controller.error.value!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      );
    }),
  );
}
