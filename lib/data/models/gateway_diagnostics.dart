class GatewayDiagnostics {
  const GatewayDiagnostics({
    required this.general,
    required this.thermal,
    required this.serviceMode,
  });

  final DiagnosticsGroup general;
  final ThermalDiagnostics thermal;
  final ServiceModeDiagnostics serviceMode;

  bool get isEmpty =>
      general.fields.isEmpty && thermal.isEmpty && serviceMode.items.isEmpty;

  factory GatewayDiagnostics.fromJson(Map<String, dynamic> json) {
    final general = _group(json['general']);
    final thermal = json['thermal'];
    final service = json['serviceMode'];
    final serviceMap = service is Map ? service : const <String, dynamic>{};
    return GatewayDiagnostics(
      general: general,
      thermal: ThermalDiagnostics.fromJson(thermal),
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

class ThermalDiagnostics {
  const ThermalDiagnostics({
    required this.source,
    required this.mode,
    required this.status,
    required this.batteryTemperatureCelsius,
    required this.thermalStatus,
    required this.thermalHeadroom,
    required this.sensors,
    required this.sampledAt,
    required this.available,
    required this.safeError,
  });

  final String source;
  final String mode;
  final String status;
  final double? batteryTemperatureCelsius;
  final String? thermalStatus;
  final double? thermalHeadroom;
  final List<ThermalSensor> sensors;
  final int sampledAt;
  final bool available;
  final String? safeError;

  bool get isEmpty => !available && sensors.isEmpty && safeError == null;

  factory ThermalDiagnostics.fromJson(Object? value) {
    final json = value is Map ? value : const <String, dynamic>{};
    return ThermalDiagnostics(
      source: _string(json['source'], 'UNAVAILABLE'),
      mode: _string(json['mode'], 'STANDARD'),
      status: _string(json['status'], 'UNKNOWN'),
      batteryTemperatureCelsius: _number(json['batteryTemperatureCelsius']),
      thermalStatus: json['thermalStatus'] is String
          ? json['thermalStatus'] as String
          : null,
      thermalHeadroom: _number(json['thermalHeadroom']),
      sensors: _sensorList(json['sensors']),
      sampledAt: json['sampledAt'] is int ? json['sampledAt'] as int : 0,
      available: json['available'] == true,
      safeError: json['safeError'] is String ? json['safeError'] as String : null,
    );
  }

  static String _string(Object? value, String fallback) =>
      value is String && value.isNotEmpty ? value : fallback;

  static double? _number(Object? value) => value is num ? value.toDouble() : null;

  static List<ThermalSensor> _sensorList(Object? value) => value is List
      ? value
            .whereType<Map>()
            .take(16)
            .map(ThermalSensor.fromJson)
            .toList()
      : const [];
}

class ThermalSensor {
  const ThermalSensor({
    required this.name,
    required this.type,
    required this.temperatureCelsius,
    required this.status,
    required this.source,
  });

  final String name;
  final String type;
  final double temperatureCelsius;
  final String status;
  final String source;

  factory ThermalSensor.fromJson(Map<dynamic, dynamic> json) => ThermalSensor(
    name: _string(json['name'], 'unknown'),
    type: _string(json['type'], 'UNKNOWN'),
    temperatureCelsius: _number(json['temperatureCelsius']),
    status: _string(json['status'], 'UNKNOWN'),
    source: _string(json['source'], 'UNKNOWN'),
  );

  static String _string(Object? value, String fallback) =>
      value is String && value.isNotEmpty ? value : fallback;

  static double _number(Object? value) => value is num ? value.toDouble() : 0;
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
