class Device {
  const Device({
    this.id,
    required this.name,
    required this.ipAddress,
    required this.macAddress,
    this.broadcastAddress = '255.255.255.255',
    this.wolPort = 9,
    this.statusCheckMethod = 'ICMP_AND_TCP',
    this.statusCheckPort = 3389,
    this.status = 'UNKNOWN',
    this.lastCheckAt,
    this.lastCheckLatencyMs,
    this.lastCheckReason,
    this.lastWolResult = 'NOT_ATTEMPTED',
    this.lastWolAt,
  });

  final int? id;
  final String name;
  final String ipAddress;
  final String macAddress;
  final String broadcastAddress;
  final int wolPort;
  final String statusCheckMethod;
  final int statusCheckPort;
  final String status;
  final DateTime? lastCheckAt;
  final int? lastCheckLatencyMs;
  final String? lastCheckReason;
  final String lastWolResult;
  final DateTime? lastWolAt;

  Device copyWith({
    String? status,
    DateTime? lastCheckAt,
    int? lastCheckLatencyMs,
    String? lastCheckReason,
    String? lastWolResult,
    DateTime? lastWolAt,
  }) => Device(
    id: id,
    name: name,
    ipAddress: ipAddress,
    macAddress: macAddress,
    broadcastAddress: broadcastAddress,
    wolPort: wolPort,
    statusCheckMethod: statusCheckMethod,
    statusCheckPort: statusCheckPort,
    status: status ?? this.status,
    lastCheckAt: lastCheckAt ?? this.lastCheckAt,
    lastCheckLatencyMs: lastCheckLatencyMs ?? this.lastCheckLatencyMs,
    lastCheckReason: lastCheckReason ?? this.lastCheckReason,
    lastWolResult: lastWolResult ?? this.lastWolResult,
    lastWolAt: lastWolAt ?? this.lastWolAt,
  );

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'] as int?,
    name: json['name'] as String,
    ipAddress: json['ipAddress'] as String,
    macAddress: json['macAddress'] as String,
    broadcastAddress: json['broadcastAddress'] as String? ?? '255.255.255.255',
    wolPort: json['wolPort'] as int? ?? 9,
    statusCheckMethod: json['statusCheckMethod'] as String? ?? 'ICMP_AND_TCP',
    statusCheckPort: json['statusCheckPort'] as int? ?? 3389,
    status: json['status'] as String? ?? 'UNKNOWN',
    lastCheckAt: _date(json['lastCheckAt']),
    lastCheckLatencyMs: json['lastCheckLatencyMs'] as int?,
    lastCheckReason: json['lastCheckReason'] as String?,
    lastWolResult: json['lastWolResult'] as String? ?? 'NOT_ATTEMPTED',
    lastWolAt: _date(json['lastWolAt']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'ipAddress': ipAddress,
    'macAddress': macAddress,
    'broadcastAddress': broadcastAddress,
    'wolPort': wolPort,
    'statusCheckMethod': statusCheckMethod,
    'statusCheckPort': statusCheckPort,
  };

  static DateTime? _date(Object? value) =>
      value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
}

class DeviceStatusResult {
  const DeviceStatusResult({
    required this.deviceId,
    required this.status,
    required this.method,
    this.latencyMs,
    this.reason,
    this.checkedAt,
  });

  final int deviceId;
  final String status;
  final String method;
  final int? latencyMs;
  final String? reason;
  final DateTime? checkedAt;

  factory DeviceStatusResult.fromJson(Map<String, dynamic> json) =>
      DeviceStatusResult(
        deviceId: json['deviceId'] as int,
        status: json['status'] as String? ?? 'UNKNOWN',
        method: json['method'] as String? ?? 'UNKNOWN',
        latencyMs: json['latencyMs'] as int?,
        reason: json['reason'] as String?,
        checkedAt: _dateValue(json['checkedAt']),
      );
}

class DeviceWakeResult {
  const DeviceWakeResult({
    required this.deviceId,
    required this.result,
    this.latencyMs,
    this.reason,
  });

  final int deviceId;
  final String result;
  final int? latencyMs;
  final String? reason;

  factory DeviceWakeResult.fromJson(Map<String, dynamic> json) =>
      DeviceWakeResult(
        deviceId: json['deviceId'] as int,
        result: json['result'] as String? ?? 'UNKNOWN',
        latencyMs: json['latencyMs'] as int?,
        reason: json['reason'] as String?,
      );
}

class DiscoveryDevice {
  const DiscoveryDevice({
    required this.ipAddress,
    this.hostName,
    this.macAddress,
    this.openPorts = const [],
  });

  final String ipAddress;
  final String? hostName;
  final String? macAddress;
  final List<int> openPorts;

  factory DiscoveryDevice.fromJson(Map<String, dynamic> json) =>
      DiscoveryDevice(
        ipAddress: json['ipAddress'] as String,
        hostName: json['hostName'] as String?,
        macAddress: json['macAddress'] as String?,
        openPorts: (json['openPorts'] as List<dynamic>? ?? const [])
            .whereType<int>()
            .toList(),
      );
}

DateTime? _dateValue(Object? value) =>
    value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
