class GatewayDiagnostics {
  const GatewayDiagnostics({required this.general, required this.serviceMode});

  final DiagnosticsGroup general;
  final ServiceModeDiagnostics serviceMode;

  bool get isEmpty => general.fields.isEmpty && serviceMode.items.isEmpty;

  factory GatewayDiagnostics.fromJson(Map<String, dynamic> json) {
    final general = _group(json['general']);
    final service = json['serviceMode'];
    final serviceMap = service is Map ? service : const <String, dynamic>{};
    return GatewayDiagnostics(
      general: general,
      serviceMode: ServiceModeDiagnostics(
        effectiveMode: _string(serviceMap['effectiveMode']),
        fallback: serviceMap['fallback'] == true,
        items:
            (serviceMap['data'] is List ? serviceMap['data'] as List : const [])
                .whereType<Map>()
                .map(DiagnosticCheck.fromJson)
                .toList(),
      ),
    );
  }

  static DiagnosticsGroup _group(Object? value) {
    if (value is! Map) return const DiagnosticsGroup([]);
    final fields = <DiagnosticsField>[];
    final checks = <DiagnosticCheck>[];
    for (final entry in value.entries) {
      final key = '${entry.key}';
      if (_blocked(key)) continue;
      if (key == 'safeErrors') {
        final errors = entry.value is List ? entry.value as List : const [];
        for (final error in errors.whereType<String>()) {
          fields.add(DiagnosticsField('Safe error', error));
        }
        continue;
      }
      if (key == 'api' || key == 'tunnel' || key == 'gatewayService') {
        final check = _check(entry.value);
        if (check != null) checks.add(check);
        continue;
      }
      _flatten(
        entry.value,
        key == 'device' || key == 'battery' ? '' : _label(key),
        fields,
      );
    }
    return DiagnosticsGroup(fields, checks);
  }

  static DiagnosticCheck? _check(Object? value) {
    if (value is! Map) return null;
    return DiagnosticCheck(
      label: '${value['label'] ?? 'Check'}',
      value: '${value['value'] ?? 'Not provided'}',
      status: '${value['status'] ?? 'UNKNOWN'}',
    );
  }

  static void _flatten(
    Object? value,
    String path,
    List<DiagnosticsField> fields,
  ) {
    if (value == null) return;
    if (_displayable(value)) {
      fields.add(
        DiagnosticsField(path.isEmpty ? 'Value' : path, _format(value)),
      );
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final key = '${entry.key}';
        if (_blocked(key)) continue;
        _flatten(
          entry.value,
          path.isEmpty ? _label(key) : '$path / ${_label(key)}',
          fields,
        );
      }
    }
  }

  static bool _displayable(Object value) =>
      value is String || value is num || value is bool;

  static String _format(Object value) {
    if (value is bool) return value ? 'Yes' : 'No';
    return '$value';
  }

  static String _string(Object? value) => value is String ? value : '';

  static String _label(String value) => _knownLabel(value)
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  static String _knownLabel(String value) =>
      const {
        'appVersion': 'App version',
        'androidVersion': 'Android',
        'deviceClassification': 'Device',
        'networkInterface': 'Network',
        'levelPercent': 'Battery level',
        'batterySaver': 'Battery saver',
      }[value] ??
      value;

  static bool _blocked(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const blockedTerms = [
      'token',
      'secret',
      'credential',
      'password',
      'authorization',
      'cookie',
      'command',
      'shell',
      'raw',
      'stdout',
      'stderr',
      'serial',
      'androidid',
      'imei',
      'identifier',
      'sensitive',
      'privatekey',
      'apikey',
    ];
    return blockedTerms.any(normalized.contains);
  }
}

class DiagnosticsGroup {
  const DiagnosticsGroup(this.fields, [this.checks = const []]);

  final List<DiagnosticsField> fields;
  final List<DiagnosticCheck> checks;
}

class ServiceModeDiagnostics {
  const ServiceModeDiagnostics({
    required this.effectiveMode,
    required this.fallback,
    required this.items,
  });

  final String effectiveMode;
  final bool fallback;
  final List<DiagnosticCheck> items;

  String get title => switch (effectiveMode) {
    'ROOT' => 'Root Mode',
    'STANDARD' => 'Standard Mode',
    _ => 'Service Mode',
  };
}

class DiagnosticCheck {
  const DiagnosticCheck({
    required this.label,
    required this.value,
    required this.status,
  });

  final String label;
  final String value;
  final String status;

  factory DiagnosticCheck.fromJson(Map<dynamic, dynamic> json) =>
      DiagnosticCheck(
        label: '${json['label'] ?? 'Check'}',
        value: '${json['value'] ?? 'Not provided'}',
        status: '${json['status'] ?? 'UNKNOWN'}',
      );
}

class DiagnosticsField {
  const DiagnosticsField(this.label, this.value);

  final String label;
  final String value;
}
