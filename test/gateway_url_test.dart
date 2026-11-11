import 'package:flutter_test/flutter_test.dart';
import 'package:wol_client/core/network/gateway_url.dart';
import 'package:wol_client/data/models/gateway.dart';

void main() {
  test('gateway round trip preserves stable sync ID', () {
    final gateway = Gateway(
      syncId: 'stable-id',
      name: 'Home',
      scheme: 'https',
      baseUrl: 'gateway.local',
      apiToken: 'secret',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
    );

    expect(Gateway.fromMap(gateway.toMap()).syncId, 'stable-id');
  });

  test('builds the fixed gateway API path', () {
    expect(
      GatewayUrl.build('https', 'gateway.example.com/'),
      'https://gateway.example.com/api/v1',
    );
  });
  test('rejects a base URL containing a scheme', () {
    expect(
      () => GatewayUrl.validate('https', 'https://gateway.example.com'),
      throwsA(isA<Exception>()),
    );
  });
}
