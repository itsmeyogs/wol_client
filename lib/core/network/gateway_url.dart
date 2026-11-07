import '../errors/gateway_failure.dart';

class GatewayUrl {
  const GatewayUrl._();

  static String build(String scheme, String baseUrl) {
    final cleanScheme = scheme.trim().toLowerCase();
    final cleanBase = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    validate(cleanScheme, cleanBase);
    return '$cleanScheme://$cleanBase/api/v1';
  }

  static void validate(String scheme, String baseUrl) {
    if (scheme != 'http' && scheme != 'https') {
      throw const GatewayFailure(
        'Choose either http or https.',
        code: 'invalid_scheme',
      );
    }
    if (baseUrl.isEmpty) {
      throw const GatewayFailure(
        'Base URL is required.',
        code: 'empty_base_url',
      );
    }
    if (baseUrl.contains('://') || baseUrl.contains(RegExp(r'\s'))) {
      throw const GatewayFailure(
        'Enter only the host/path without http:// or https://.',
        code: 'invalid_base_url',
      );
    }
    final uri = Uri.tryParse('$scheme://$baseUrl/api/v1');
    if (uri == null || uri.host.isEmpty || uri.hasQuery || uri.hasFragment) {
      throw const GatewayFailure(
        'Base URL is invalid.',
        code: 'invalid_base_url',
      );
    }
  }
}
