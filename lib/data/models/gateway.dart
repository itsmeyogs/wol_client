import '../../core/network/gateway_url.dart';

class Gateway {
  const Gateway({
    this.id,
    required this.name,
    required this.scheme,
    required this.baseUrl,
    required this.apiToken,
    required this.createdAt,
    required this.updatedAt,
  });
  final int? id;
  final String name;
  final String scheme;
  final String baseUrl;
  final String apiToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  String get apiBaseUrl => GatewayUrl.build(scheme, baseUrl);

  factory Gateway.fromMap(Map<String, Object?> map) => Gateway(
    id: map['id'] as int?,
    name: map['name'] as String,
    scheme: map['scheme'] as String,
    baseUrl: map['base_url'] as String,
    apiToken: map['api_token'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'scheme': scheme,
    'base_url': baseUrl,
    'api_token': apiToken,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };
}
