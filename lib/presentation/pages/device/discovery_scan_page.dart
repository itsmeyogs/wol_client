import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../data/models/device.dart';
import '../../controllers/discovery_scan_controller.dart';

class DiscoveryScanPage extends StatefulWidget {
  const DiscoveryScanPage({super.key});

  @override
  State<DiscoveryScanPage> createState() => _DiscoveryScanPageState();
}

class _DiscoveryScanPageState extends State<DiscoveryScanPage> {
  late final DiscoveryScanController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DiscoveryScanController>()..discover();
  }

  Future<void> _openResult(DiscoveryDevice device) async {
    final result = await Get.toNamed(AppRoutes.deviceForm, arguments: device);
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  Future<void> _addManually() async {
    final result = await Get.toNamed(AppRoutes.deviceForm);
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  Future<void> _refresh() async {
    await controller.discover();
    if (!mounted) return;
    if (controller.discoveryError.value == null) {
      AppSnackbar.success('Device discovery completed.');
    } else {
      AppSnackbar.error(controller.discoveryError.value!);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Discover devices'),
      actions: [
        if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
          Obx(
            () => IconButton(
              tooltip: 'Scan again',
              onPressed: controller.isDiscovering.value ? null : _refresh,
              icon: controller.isDiscovering.value
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ),
      ],
    ),
    body: Obx(() {
      if (controller.isDiscovering.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.discoveryError.value != null) {
        final errorState = _MessageState(
          message: controller.discoveryError.value!,
          action: _isDesktop
              ? OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan again'),
                )
              : const SizedBox.shrink(),
        );
        return _isAndroid
            ? RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * .65,
                      child: errorState,
                    ),
                  ],
                ),
              )
            : errorState;
      }
      if (controller.discovered.isEmpty) {
        final emptyState = _MessageState(
          message: 'No devices found on the LAN.',
          action: _isDesktop
              ? OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan again'),
                )
              : const SizedBox.shrink(),
        );
        return _isAndroid
            ? RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * .65,
                      child: emptyState,
                    ),
                  ],
                ),
              )
            : emptyState;
      }
      final content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: controller.discovered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final device = controller.discovered[index];
              return Card(
                child: ListTile(
                  onTap: () => _openResult(device),
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
          ),
        ),
      );
      return _isAndroid
          ? RefreshIndicator(onRefresh: _refresh, child: content)
          : content;
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

bool get _isDesktop =>
    kIsWeb || defaultTargetPlatform == TargetPlatform.windows;
bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
