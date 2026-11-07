import 'package:flutter_test/flutter_test.dart';
import 'package:wol_client/core/network/gateway_url.dart';

void main() {
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
