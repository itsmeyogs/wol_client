import 'package:flutter_test/flutter_test.dart';
import 'package:wol_client/data/models/gateway_diagnostics.dart';

void main() {
  test('parses the current general and standard mode contract', () {
    final diagnostics = GatewayDiagnostics.fromJson({
      'general': {
        'appVersion': '1.0',
        'androidVersion': '14',
        'deviceClassification': 'OTHER',
        'api': {'label': 'API', 'value': 'Running', 'status': 'PASS'},
        'tunnel': {'label': 'Tunnel', 'value': 'Connected', 'status': 'PASS'},
        'safeErrors': [],
        'device': {'manufacturer': 'Google', 'model': 'Pixel 7'},
        'apiToken': 'hidden',
      },
      'serviceMode': {
        'effectiveMode': 'STANDARD',
        'fallback': false,
        'data': [
          {'label': 'Service running', 'value': 'Running', 'status': 'PASS'},
          {'label': 'Boot recovery', 'value': 'Best effort', 'status': 'WARN'},
        ],
      },
    });

    expect(
      diagnostics.general.fields.map((field) => field.value),
      contains('Pixel 7'),
    );
    expect(
      diagnostics.general.fields.map((field) => field.value),
      isNot(contains('hidden')),
    );
    expect(diagnostics.general.checks, hasLength(2));
    expect(diagnostics.general.checks.first.label, 'API');
    expect(diagnostics.serviceMode.title, 'Standard Mode');
    expect(diagnostics.serviceMode.items, hasLength(2));
    expect(diagnostics.serviceMode.items.last.status, 'WARN');
  });

  test('parses root fallback and preserves all mode checks', () {
    final diagnostics = GatewayDiagnostics.fromJson({
      'general': {
        'safeErrors': ['Root unavailable'],
      },
      'serviceMode': {
        'effectiveMode': 'STANDARD',
        'fallback': true,
        'data': List.generate(
          8,
          (index) => {
            'label': 'Check $index',
            'value': 'Enabled',
            'status': index == 6 ? 'NOT_CONFIGURED' : 'PASS',
          },
        ),
      },
    });

    expect(diagnostics.serviceMode.fallback, isTrue);
    expect(diagnostics.serviceMode.items, hasLength(8));
    expect(diagnostics.general.fields.single.value, 'Root unavailable');
  });

  test('formats camel case labels without replacement tokens', () {
    final diagnostics = GatewayDiagnostics.fromJson({
      'general': {
        'appVersion': '1.0',
        'androidVersion': '14',
        'networkInterface': 'wlan0',
      },
    });

    final labels = diagnostics.general.fields.map((field) => field.label);
    expect(labels, contains('App Version'));
    expect(labels, contains('Android'));
    expect(labels, contains('Network'));
    expect(labels.join(' '), isNot(contains(r'$1')));
  });
}
