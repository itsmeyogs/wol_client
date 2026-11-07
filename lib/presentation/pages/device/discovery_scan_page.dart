import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/device.dart';
import '../../controllers/device_controller.dart';
import 'device_add_edit_page.dart';

class DiscoveryScanPage extends StatefulWidget {
  const DiscoveryScanPage({super.key});

  @override
  State<DiscoveryScanPage> createState() => _DiscoveryScanPageState();
}

class _DiscoveryScanPageState extends State<DiscoveryScanPage> {
  late final DeviceController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DeviceController>()..discover();
  }

  Future<void> _openResult(DiscoveryDevice device) async {
    final saved = await Get.to<bool>(
      () => DeviceAddEditPage(discovery: device),
    );
    if (saved == true && mounted) Get.back(result: true);
  }

  Future<void> _addManually() async {
    final saved = await Get.to<bool>(() => const DeviceAddEditPage());
    if (saved == true && mounted) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Discover devices')),
    body: Obx(() {
      if (controller.isDiscovering.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.discoveryError.value != null) {
        return _MessageState(
          message: controller.discoveryError.value!,
          action: OutlinedButton.icon(
            onPressed: controller.discover,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan again'),
          ),
        );
      }
      if (controller.discovered.isEmpty) {
        return _MessageState(
          message: 'No devices found on the LAN.',
          action: OutlinedButton.icon(
            onPressed: controller.discover,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan again'),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: controller.discovered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final device = controller.discovered[index];
          return Card(
            child: ListTile(
              onTap: () => _openResult(device),
              leading: const Icon(Icons.computer_outlined),
              title: Text(
                device.hostName?.isNotEmpty == true
                    ? device.hostName!
                    : device.ipAddress,
              ),
              subtitle: Text(
                '${device.ipAddress} • ${device.macAddress ?? 'MAC unavailable'}',
              ),
              trailing: device.openPorts.isEmpty
                  ? const Icon(Icons.chevron_right)
                  : Text(device.openPorts.join(', ')),
            ),
          );
        },
      );
    }),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: FilledButton.icon(
        onPressed: _addManually,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Add manually'),
      ),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.action});

  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          action,
        ],
      ),
    ),
  );
}
