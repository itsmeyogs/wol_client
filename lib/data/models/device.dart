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
