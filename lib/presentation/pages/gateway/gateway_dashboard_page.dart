import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../data/models/device.dart';
import '../../controllers/device_controller.dart';
import '../../controllers/gateway_session_controller.dart';
import '../device/device_add_edit_page.dart';
import '../device/discovery_scan_page.dart';

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
    final saved = await Get.to<bool>(() => const DiscoveryScanPage());
    if (saved == true && mounted) await controller.load();
  }

  Future<void> _delete(Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete device?'),
        content: Text('Remove ${device.name}?'),
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
    if (confirmed == true) {
      await controller.deleteDevice(device);
      AppSnackbar.success('Device deleted.');
    }
  }

  Future<void> _actions(Device device) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit device'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete device'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      final saved = await Get.to<bool>(() => DeviceAddEditPage(device: device));
      if (saved == true && mounted) await controller.load();
    }
    if (action == 'delete') _delete(device);
  }

  @override
  Widget build(BuildContext context) {
    final gateway = Get.find<GatewaySessionController>().activeGateway.value;
    final padding = AppResponsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(title: Text(gateway?.name ?? 'Gateway')),
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
                child: ListTile(
                  onLongPress: () => _actions(device),
                  title: Text(device.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(device.ipAddress), Text(device.macAddress)],
                  ),
                  trailing: Text(device.status),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
