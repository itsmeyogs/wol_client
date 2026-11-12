import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:get/get.dart';
import '../../../core/errors/gateway_failure.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/gateway.dart';
import '../../controllers/gateway_list_controller.dart';
import '../settings/settings_page.dart';
import 'gateway_dashboard_page.dart';
import 'gateway_form_page.dart';
import '../../../core/logging/app_logger.dart';

class GatewayListPage extends GetView<GatewayListController> {
  const GatewayListPage({super.key});
  void _open(Gateway gateway) {
    controller.openGateway(gateway);
    Get.to(() => const GatewayDashboardPage());
  }

  Future<void> _delete(BuildContext context, Gateway gateway) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete gateway?'),
        content: Text('Remove ${gateway.name} from this device?'),
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
      try {
        await controller.deleteGateway(gateway);
        AppSnackbar.success('Gateway deleted.');
      } on GatewayFailure catch (failure) {
        AppSnackbar.error(failure.message);
      } catch (exception, stackTrace) {
        AppLogger.instance.error(
          'Gateway delete failed: ${exception.runtimeType}',
          exception,
          stackTrace,
        );
        AppSnackbar.error('Gateway could not be deleted.');
      }
    }
  }

  Future<void> _form(Gateway? gateway) async {
    final result = await Get.to<String>(
      () => GatewayFormPage(gateway: gateway),
    );
    if (result == 'added') AppSnackbar.success('Gateway added.');
    if (result == 'updated') AppSnackbar.success('Gateway updated.');
  }

  Future<void> _showActions(BuildContext context, Gateway gateway) async {
    final action = await showModalBottomSheet<_GatewayAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit gateway'),
              onTap: () => Navigator.pop(context, _GatewayAction.edit),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete gateway',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.pop(context, _GatewayAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _GatewayAction.edit:
        _form(gateway);
      case _GatewayAction.delete:
        _delete(context, gateway);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = AppResponsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('WoL gateways'),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Refresh gateways',
              onPressed: controller.isRefreshing ? null : controller.refresh,
              icon: controller.isRefreshing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Get.to(() => const SettingsPage()),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(null),
        tooltip: 'Add gateway',
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.gateways.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null && controller.gateways.isEmpty) {
          return _MessageState(
            message: controller.error.value!,
            onRetry: controller.refresh,
          );
        }
        if (controller.gateways.isEmpty) {
          return _EmptyGateways(onAdd: () => _form(null));
        }
        final content = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppResponsive.contentWidth(context),
          ),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 100),
            itemCount: controller.gateways.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final gateway = controller.gateways[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(gateway),
                  onLongPress: () => _showActions(context, gateway),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gateway.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${gateway.scheme}://${gateway.baseUrl}/api/v1',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
        final list = Center(child: content);
        return defaultTargetPlatform == TargetPlatform.android && !kIsWeb
            ? RefreshIndicator(onRefresh: controller.refresh, child: list)
            : list;
      }),
    );
  }
}

enum _GatewayAction { edit, delete }

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.onRetry});
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

class _EmptyGateways extends StatelessWidget {
  const _EmptyGateways({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.router_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Connect your first gateway',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a WoL gateway to discover devices and send wake packets.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add gateway'),
            ),
          ],
        ),
      ),
    ),
  );
}
