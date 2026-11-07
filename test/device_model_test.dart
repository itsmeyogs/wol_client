import 'package:flutter_test/flutter_test.dart';
import 'package:wol_client/data/models/device.dart';

void main() {
  test('parses device response and sends only writable fields', () {
    final device = Device.fromJson({
      'id': 7,
      'name': 'Office PC',
      'ipAddress': '192.168.1.20',
      'macAddress': 'AA:BB:CC:DD:EE:FF',
      'status': 'ONLINE',
      'lastCheckAt': 1730000000000,
    });

    expect(device.id, 7);
    expect(device.status, 'ONLINE');
    expect(device.toJson(), {
      'name': 'Office PC',
      'ipAddress': '192.168.1.20',
      'macAddress': 'AA:BB:CC:DD:EE:FF',
      'broadcastAddress': '255.255.255.255',
      'wolPort': 9,
      'statusCheckMethod': 'ICMP_AND_TCP',
      'statusCheckPort': 3389,
    });
  });

  test('parses discovery result with nullable MAC', () {
    final device = DiscoveryDevice.fromJson({
      'ipAddress': '192.168.1.21',
      'hostName': 'LAPTOP',
      'macAddress': null,
      'openPorts': [3389, 445],
    });

    expect(device.hostName, 'LAPTOP');
    expect(device.macAddress, isNull);
    expect(device.openPorts, [3389, 445]);
  });
}
