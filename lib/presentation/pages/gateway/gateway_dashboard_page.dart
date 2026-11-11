import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/errors/gateway_failure.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../data/models/device.dart';
import '../../controllers/device_controller.dart';
import '../../controllers/gateway_session_controller.dart';
import '../device/device_detail_page.dart';
import '../device/discovery_scan_page.dart';
import '../diagnostics/diagnostics_page.dart';
import '../../../core/logging/app_logger.dart';

class GatewayDashboardPage extends StatefulWidget {
  const GatewayDashboardPage({super.key});
  @override
  State<GatewayDashboardPage> createState() => _GatewayDashboardPageState();
}

class _GatewayDashboardPageState extends State<GatewayDashboardPage> {
  late final DeviceController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DeviceController>()..load();
  }

  Future<void> _add() async {
    final result = await Get.to<String>(() => const DiscoveryScanPage());
    if (result != null && mounted) {
      await controller.load();
      if (controller.error.value == null) {
        AppSnackbar.success(
          result == 'updated' ? 'Device updated.' : 'Device added.',
        );
      } else {
        AppSnackbar.error(controller.error.value!);
      }
    }
  }

  Future<void> _wake(Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wake device?'),
        content: Text('Send a magic packet to ${device.name}?'),
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
      final result = await controller.wake(device);
      AppSnackbar.success(
        '${result.result}: packet delivery does not prove the computer powered on.',
      );
    } on GatewayFailure catch (failure) {
      AppSnackbar.error(failure.message);
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Device wake failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      AppSnackbar.error('Wake packet could not be sent.');
    }
  }

  Future<void> _open(Device device) async {
    final result = await Get.to<String>(
      () => DeviceDetailPage(deviceId: device.id!),
    );
    if (result == 'deleted' && mounted) {
      await controller.load();
      if (controller.error.value == null) {
        AppSnackbar.success('Device deleted.');
      } else {
        AppSnackbar.error(controller.error.value!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gateway = Get.find<GatewaySessionController>().activeGateway.value;
    final padding = AppResponsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(gateway?.name ?? 'Gateway'),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const DiagnosticsPage()),
            tooltip: 'Gateway diagnostics',
            icon: const Icon(Icons.monitor_heart_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Add device',
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.devices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null && controller.devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.error.value!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (controller.devices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.computer_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No devices yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a device manually or discover devices on the LAN.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Add device'),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(padding, 12, padding, 100),
            itemCount: controller.devices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final device = controller.devices[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(device),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                device.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            _StatusBadge(status: device.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(device.ipAddress),
                        Text(device.macAddress),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Last checked: ${_time(device.lastCheckAt)}',
                              ),
                            ),
                            if (device.status != 'ONLINE')
                              TextButton.icon(
                                onPressed: () => _wake(device),
                                icon: const Icon(Icons.power_settings_new),
                                label: const Text('Wake up'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  String _time(DateTime? value) {
    if (value == null) return 'Never';
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
