import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:get/get.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../data/models/gateway_diagnostics.dart';
import '../../controllers/diagnostics_controller.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  late final DiagnosticsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DiagnosticsController>()..load();
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppResponsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
            Obx(
              () => IconButton(
                tooltip: 'Refresh diagnostics',
                onPressed: controller.isLoading.value ? null : controller.load,
                icon: controller.isLoading.value
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
        if (controller.isLoading.value &&
            controller.diagnostics.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final message = controller.error.value;
        if (message != null && controller.diagnostics.value == null) {
          final errorState = _DiagnosticsErrorMessage(
            message: message,
            onRetry: controller.load,
          );
          return _isAndroid
              ? RefreshIndicator(
                  onRefresh: controller.load,
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
        final snapshot = controller.diagnostics.value;
        if (snapshot == null || snapshot.isEmpty) {
          return _EmptyState(onRetry: controller.load);
        }
        final content = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppResponsive.contentWidth(context),
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
              children: [
                if (message != null) ...[
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _GeneralSection(group: snapshot.general),
                _ThermalSection(thermal: snapshot.thermal),
                _ServiceModeSection(mode: snapshot.serviceMode),
              ],
            ),
          ),
        );
        return _isAndroid
            ? RefreshIndicator(onRefresh: controller.load, child: content)
            : content;
      }),
    );
  }
}

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

class _DiagnosticsErrorMessage extends StatelessWidget {
  const _DiagnosticsErrorMessage({
    required this.message,
    required this.onRetry,
  });
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _GeneralSection extends StatelessWidget {
  const _GeneralSection({required this.group});

  final DiagnosticsGroup group;

  @override
  Widget build(BuildContext context) => _DiagnosticsCard(
    title: 'General',
    children: [
      ...group.fields.map((field) => _Field(field: field)),
      ...group.checks.map((item) => _Check(item: item)),
    ],
  );
}

class _ServiceModeSection extends StatelessWidget {
  const _ServiceModeSection({required this.mode});

  final ServiceModeDiagnostics mode;

  @override
  Widget build(BuildContext context) => _DiagnosticsCard(
    title: mode.title,
    children: [
      _Field(field: DiagnosticsField('Effective mode', mode.effectiveMode)),
      _Field(field: DiagnosticsField('Fallback', mode.fallback ? 'Yes' : 'No')),
      ...mode.items.map((item) => _Check(item: item)),
    ],
  );
}

class _ThermalSection extends StatelessWidget {
  const _ThermalSection({required this.thermal});

  final ThermalDiagnostics thermal;

  @override
  Widget build(BuildContext context) => _DiagnosticsCard(
    title: 'Thermal',
    children: [
      _Field(field: DiagnosticsField('Status', _label(thermal.status))),
      _Field(
        field: DiagnosticsField('Available', thermal.available ? 'Yes' : 'No'),
      ),
      _Field(field: DiagnosticsField('Source', _label(thermal.source))),
      _Field(field: DiagnosticsField('Mode', _label(thermal.mode))),
      if (thermal.batteryTemperatureCelsius != null)
        _Field(
          field: DiagnosticsField(
            'Battery temperature',
            '${thermal.batteryTemperatureCelsius!.toStringAsFixed(1)} °C',
          ),
        ),
      if (thermal.thermalStatus != null)
        _Field(
          field: DiagnosticsField(
            'Android thermal status',
            _label(thermal.thermalStatus!),
          ),
        ),
      if (thermal.thermalHeadroom != null)
        _Field(
          field: DiagnosticsField(
            'Thermal headroom',
            thermal.thermalHeadroom!.toStringAsFixed(2),
          ),
        ),
      if (thermal.sampledAt > 0)
        _Field(field: DiagnosticsField('Sampled at', _time(thermal.sampledAt))),
      if (thermal.safeError != null)
        _Field(field: DiagnosticsField('Safe error', thermal.safeError!)),
      ...thermal.sensors.map(
        (sensor) => _Field(
          field: DiagnosticsField(
            '${_label(sensor.name)} (${_label(sensor.type)})',
            '${sensor.temperatureCelsius.toStringAsFixed(1)} °C · ${_label(sensor.status)}',
          ),
        ),
      ),
      if (!thermal.available && thermal.sensors.isEmpty)
        const _Field(
          field: DiagnosticsField('Temperature data', 'Unavailable'),
        ),
    ],
  );

  String _label(String value) => value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');

  String _time(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal().toString();
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.field});

  final DiagnosticsField field;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(field.label)),
        const SizedBox(width: 16),
        Flexible(child: Text(field.value, textAlign: TextAlign.right)),
      ],
    ),
  );
}

class _Check extends StatelessWidget {
  const _Check({required this.item});

  final DiagnosticCheck item;

  @override
  Widget build(BuildContext context) {
    final status = item.status.toLowerCase();
    final color = status == 'pass'
        ? Colors.green
        : status == 'warn'
        ? Colors.orange
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(item.label)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.value, textAlign: TextAlign.right),
              Text(
                _statusLabel(item.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String value) => switch (value.toUpperCase()) {
    'PASS' => 'pass',
    'WARN' => 'warn',
    'NOT_CONFIGURED' => 'not configured',
    _ => value.toLowerCase(),
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No safe diagnostics are available.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Refresh')),
        ],
      ),
    ),
  );
}
