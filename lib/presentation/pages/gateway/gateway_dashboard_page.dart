import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:get/get.dart';
import '../../../core/errors/gateway_failure.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../data/models/device.dart';
import '../../controllers/gateway_dashboard_controller.dart';
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
  late final GatewayDashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<GatewayDashboardController>()..load();
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
          final errorList = ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * .7,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.error.value!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: controller.load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
          return defaultTargetPlatform == TargetPlatform.android && !kIsWeb
              ? RefreshIndicator(onRefresh: controller.load, child: errorList)
              : errorList;
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
        final content = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppResponsive.contentWidth(context),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              final rows = <Widget>[];
              for (
                var index = 0;
                index < controller.devices.length;
                index += columns
              ) {
                final rowDevices = controller.devices
                    .skip(index)
                    .take(columns)
                    .toList();
                final children = <Widget>[];
                for (var column = 0; column < rowDevices.length; column++) {
                  if (column > 0) children.add(const SizedBox(width: 16));
                  final device = rowDevices[column];
                  children.add(
                    Expanded(
                      child: _DeviceTile(
                        device: device,
                        onOpen: () => _open(device),
                        onWake: () => _wake(device),
                        time: _time(device.lastCheckAt),
                      ),
                    ),
                  );
                }
                if (rowDevices.length < columns)
                  children.add(const Expanded(child: SizedBox()));
                rows.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                );
              }
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(padding, 16, padding, 100),
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    rows[i],
                  ],
                ],
              );
            },
          ),
        );
        final list = Center(child: content);
        return defaultTargetPlatform == TargetPlatform.android && !kIsWeb
            ? RefreshIndicator(onRefresh: controller.load, child: list)
            : list;
      }),
    );
  }

  String _time(DateTime? value) {
    if (value == null) return 'Never';
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.onOpen,
    required this.onWake,
    required this.time,
  });
  final Device device;
  final VoidCallback onOpen;
  final VoidCallback onWake;
  final String time;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 12),
            SelectableText(
              '${device.ipAddress}\n${device.macAddress}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Last checked: $time',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (device.status != 'ONLINE')
                  TextButton.icon(
                    onPressed: onWake,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Wake'),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
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
