import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/errors/gateway_failure.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../data/models/device.dart';
import '../../controllers/device_detail_controller.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({super.key, this.deviceId});

  final int? deviceId;

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late final DeviceDetailController controller;

  int get _resolvedDeviceId =>
      widget.deviceId ??
      (Get.arguments is int
          ? Get.arguments as int
          : int.tryParse(Get.parameters['id'] ?? '') ?? 0);

  @override
  void initState() {
    super.initState();
    controller = Get.find<DeviceDetailController>();
    controller.load(_resolvedDeviceId);
  }

  Future<void> _reload() => controller.load(_resolvedDeviceId);

  Future<void> _checkStatus() async {
    try {
      final result = await controller.checkStatus();
      AppSnackbar.success('Status checked: ${result.status}.');
    } on GatewayFailure catch (failure) {
      AppSnackbar.error(failure.message);
    } catch (_) {
      AppSnackbar.error('Device status could not be checked.');
    }
  }

  Future<void> _wake() async {
    final current = controller.device.value;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wake device?'),
        content: Text('Send a magic packet to ${current.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wake up'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await controller.wake();
      AppSnackbar.success(
        '${result.result}: packet delivery does not prove the computer powered on.',
      );
    } on GatewayFailure catch (failure) {
      AppSnackbar.error(failure.message);
    } catch (_) {
      AppSnackbar.error('Wake packet could not be sent.');
    }
  }

  Future<void> _edit() async {
    final current = controller.device.value;
    if (current == null) return;
    final result = await Get.toNamed(AppRoutes.deviceForm, arguments: current);
    if (result == 'updated') {
      await _reload();
      if (controller.error.value == null) {
        AppSnackbar.success('Device updated.');
      } else {
        AppSnackbar.error(controller.error.value!);
      }
    }
  }

  Future<void> _delete() async {
    final current = controller.device.value;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete device?'),
        content: Text('Remove ${current.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.delete();
      if (mounted) Navigator.of(context).pop('deleted');
    } on GatewayFailure catch (failure) {
      AppSnackbar.error(failure.message);
    } catch (_) {
      AppSnackbar.error('Device could not be deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.device.value;
      return Scaffold(
        appBar: AppBar(
          title: Text(current?.name ?? 'Device details'),
          actions: [
            if (current != null)
              IconButton(
                onPressed: _edit,
                tooltip: 'Edit device',
                icon: const Icon(Icons.edit_outlined),
              ),
            if (current != null)
              IconButton(
                onPressed: _delete,
                tooltip: 'Delete device',
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : controller.error.value != null
            ? _ErrorState(message: controller.error.value!, onRetry: _reload)
            : current == null
            ? _ErrorState(message: 'Device was not found.', onRetry: _reload)
            : _Details(
                device: current,
                controller: controller,
                onCheckStatus: _checkStatus,
                onWake: _wake,
              ),
      );
    });
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.device,
    required this.controller,
    required this.onCheckStatus,
    required this.onWake,
  });

  final Device device;
  final DeviceDetailController controller;
  final VoidCallback onCheckStatus;
  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              _StatusBadge(status: device.status),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680 ? 2 : 1;
              final details = [
                _Detail(label: 'IP address', value: device.ipAddress),
                _Detail(label: 'MAC address', value: device.macAddress),
                _Detail(label: 'Broadcast', value: device.broadcastAddress),
                _Detail(label: 'WoL port', value: '${device.wolPort}'),
                _Detail(label: 'Check method', value: device.statusCheckMethod),
                _Detail(
                  label: 'Check port',
                  value: '${device.statusCheckPort}',
                ),
                _Detail(
                  label: 'Last checked',
                  value: _time(device.lastCheckAt),
                ),
                _Detail(
                  label: 'Latency',
                  value: device.lastCheckLatencyMs == null
                      ? 'Not provided'
                      : '${device.lastCheckLatencyMs} ms',
                ),
                _Detail(
                  label: 'Reason',
                  value: device.lastCheckReason ?? 'Not provided',
                ),
              ];
              if (columns == 1) return Column(children: details);
              return Wrap(
                spacing: 32,
                runSpacing: 4,
                children: [
                  for (final detail in details)
                    SizedBox(
                      width: (constraints.maxWidth - 32) / 2,
                      child: detail,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Obx(
            () => FilledButton.icon(
              onPressed: controller.isCheckingStatus.value
                  ? null
                  : onCheckStatus,
              icon: controller.isCheckingStatus.value
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_outlined),
              label: const Text('Check status'),
            ),
          ),
          if (device.status != 'ONLINE') ...[
            const SizedBox(height: 12),
            Obx(
              () => OutlinedButton.icon(
                onPressed: controller.isWaking.value ? null : onWake,
                icon: controller.isWaking.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.power_settings_new),
                label: const Text('Wake up'),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  String _time(DateTime? value) {
    if (value == null) return 'Never checked';
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ONLINE' => Colors.green,
      'OFFLINE' => Theme.of(context).colorScheme.error,
      _ => Colors.orange,
    };
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(status),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
