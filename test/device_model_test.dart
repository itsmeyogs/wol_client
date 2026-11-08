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

  test('parses status and wake results', () {
    final status = DeviceStatusResult.fromJson({
      'deviceId': 7,
      'status': 'ONLINE',
      'method': 'ICMP_AND_TCP',
      'latencyMs': 42,
      'reason': 'tcp_connected',
      'checkedAt': 1730000000000,
    });
    final wake = DeviceWakeResult.fromJson({
      'deviceId': 7,
      'result': 'PACKET_SENT',
      'latencyMs': 8,
      'reason': 'packet_sent',
    });

    expect(status.status, 'ONLINE');
    expect(status.latencyMs, 42);
    expect(wake.result, 'PACKET_SENT');
    expect(wake.reason, 'packet_sent');
  });

  test('parses a device detail response', () {
    final device = Device.fromJson({
      'id': 12,
      'name': 'Living Room PC',
      'ipAddress': '192.168.1.12',
      'macAddress': '00:11:22:33:44:55',
      'broadcastAddress': '192.168.1.255',
      'wolPort': 9,
      'statusCheckMethod': 'ICMP_AND_TCP',
      'statusCheckPort': 3389,
      'status': 'OFFLINE',
      'lastCheckAt': 1730000000000,
      'lastCheckLatencyMs': 120,
      'lastCheckReason': 'tcp_timeout',
      'lastWolResult': 'PACKET_SENT',
      'lastWolAt': 1730000001000,
    });

    expect(device.id, 12);
    expect(device.status, 'OFFLINE');
    expect(device.lastCheckLatencyMs, 120);
    expect(device.lastCheckReason, 'tcp_timeout');
    expect(device.lastWolResult, 'PACKET_SENT');
  });
}
