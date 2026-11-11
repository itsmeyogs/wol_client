import '../../core/network/gateway_url.dart';

class Gateway {
  const Gateway({
    this.id,
    this.syncId,
    required this.name,
    required this.scheme,
    required this.baseUrl,
    required this.apiToken,
    required this.createdAt,
    required this.updatedAt,
  });
  final int? id;
  final String? syncId;
  final String name;
  final String scheme;
  final String baseUrl;
  final String apiToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  String get apiBaseUrl => GatewayUrl.build(scheme, baseUrl);

  Gateway copyWith({
    int? id,
    String? syncId,
    String? name,
    String? scheme,
    String? baseUrl,
    String? apiToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Gateway(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    name: name ?? this.name,
    scheme: scheme ?? this.scheme,
    baseUrl: baseUrl ?? this.baseUrl,
    apiToken: apiToken ?? this.apiToken,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Gateway.fromMap(Map<String, Object?> map) => Gateway(
    id: map['id'] as int?,
    syncId: map['sync_id'] as String?,
    name: map['name'] as String,
    scheme: map['scheme'] as String,
    baseUrl: map['base_url'] as String,
    apiToken: map['api_token'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    if (syncId != null) 'sync_id': syncId,
    'name': name,
    'scheme': scheme,
    'base_url': baseUrl,
    'api_token': apiToken,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };
}
