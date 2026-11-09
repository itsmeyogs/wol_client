import 'package:dio/dio.dart';
import '../errors/gateway_failure.dart';
import '../logging/app_logger.dart';
import '../../data/models/gateway.dart';
import '../../data/models/device.dart';
import '../../data/models/gateway_diagnostics.dart';

class DioClient {
  DioClient._() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.info('${options.method} ${options.uri.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.info(
            '${response.statusCode} ${response.requestOptions.uri.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.error(
            '${error.requestOptions.method} ${error.requestOptions.uri.path} failed',
            _safeError(error),
          );
          handler.next(error);
        },
      ),
    );
  }

  static final instance = DioClient._();
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );
  final AppLogger _logger = AppLogger.instance;

  Future<void> validateGateway(Gateway gateway) async {
    try {
      final response = await dio.get('${gateway.apiBaseUrl}/health');
      if (response.data is! Map || response.data['status'] != 'ok') {
        throw const GatewayFailure(
          'Gateway health response is invalid.',
          code: 'invalid_api',
        );
      }
    } on GatewayFailure {
      rethrow;
    } on DioException catch (error) {
      throw _mapError(error, healthCheck: true);
    }
    try {
      final response = await dio.get(
        '${gateway.apiBaseUrl}/diagnostics',
        options: Options(
          headers: {'Authorization': 'Bearer ${gateway.apiToken}'},
        ),
      );
      _diagnosticsJson(response.data);
    } on DioException catch (error) {
      throw _mapError(error, healthCheck: false);
    }
  }

  Future<GatewayDiagnostics> getDiagnostics(Gateway gateway) async {
    final response = await _request(
      () =>
          dio.get('${gateway.apiBaseUrl}/diagnostics', options: _auth(gateway)),
    );
    return GatewayDiagnostics.fromJson(_diagnosticsJson(response.data));
  }

  Future<List<Device>> getDevices(Gateway gateway) async {
    final response = await _request(
      () => dio.get('${gateway.apiBaseUrl}/devices', options: _auth(gateway)),
    );
    final data = response.data;
    if (data is! List) {
      throw const GatewayFailure(
        'Device list response is invalid.',
        code: 'invalid_api',
      );
    }
    try {
      return data
          .map(
            (item) =>
                Device.fromJson(_jsonMap(item, 'Device response is invalid.')),
          )
          .toList();
    } on GatewayFailure {
      rethrow;
    } catch (_) {
      throw const GatewayFailure(
        'Device list response is invalid.',
        code: 'invalid_api',
      );
    }
  }

  Future<Device> getDevice(Gateway gateway, int id) async {
    final response = await _request(
      () =>
          dio.get('${gateway.apiBaseUrl}/devices/$id', options: _auth(gateway)),
    );
    try {
      return Device.fromJson(
        _jsonMap(response.data, 'Device response is invalid.'),
      );
    } on GatewayFailure {
      rethrow;
    } catch (_) {
      throw const GatewayFailure(
        'Device response is invalid.',
        code: 'invalid_api',
      );
    }
  }

  Future<Device> saveDevice(Gateway gateway, Device device) async {
    final response = await _request(() {
      final path = device.id == null
          ? '${gateway.apiBaseUrl}/devices'
          : '${gateway.apiBaseUrl}/devices/${device.id}';
      return device.id == null
          ? dio.post(path, data: device.toJson(), options: _auth(gateway))
          : dio.put(path, data: device.toJson(), options: _auth(gateway));
    });
    try {
      return Device.fromJson(
        _jsonMap(response.data, 'Device response is invalid.'),
      );
    } on GatewayFailure {
      rethrow;
    } catch (_) {
      throw const GatewayFailure(
        'Device response is invalid.',
        code: 'invalid_api',
      );
    }
  }

  Future<void> deleteDevice(Gateway gateway, int id) async {
    await _request(
      () => dio.delete(
        '${gateway.apiBaseUrl}/devices/$id',
        options: _auth(gateway),
      ),
    );
  }

  Future<List<DiscoveryDevice>> discoverDevices(Gateway gateway) async {
    final response = await _request(
      () => dio.post(
        '${gateway.apiBaseUrl}/discovery/scan',
        options: _auth(gateway),
      ),
    );
    final data = _jsonMap(response.data, 'Discovery response is invalid.');
    final devices = data['devices'];
    if (devices is! List) {
      throw const GatewayFailure(
        'Discovery response is invalid.',
        code: 'invalid_api',
      );
    }
    try {
      return devices
          .map(
            (item) => DiscoveryDevice.fromJson(
              _jsonMap(item, 'Discovery response is invalid.'),
            ),
          )
          .toList();
    } on GatewayFailure {
      rethrow;
    } catch (_) {
      throw const GatewayFailure(
        'Discovery response is invalid.',
        code: 'invalid_api',
      );
    }
  }

  Future<DeviceStatusResult> getDeviceStatus(Gateway gateway, int id) async {
    final response = await _request(
      () => dio.get(
        '${gateway.apiBaseUrl}/devices/$id/status',
        options: _auth(gateway),
      ),
    );
    try {
      return DeviceStatusResult.fromJson(
        _jsonMap(response.data, 'Device status response is invalid.'),
      );
    } on GatewayFailure {
      rethrow;
    } catch (_) {
      throw const GatewayFailure(
        'Device status response is invalid.',
        code: 'invalid_api',
      );
    }
  }

  Future<DeviceWakeResult> wakeDevice(Gateway gateway, int id) async {
    final response = await _request(
      () => dio.post(
        '${gateway.apiBaseUrl}/devices/$id/wake',
        options: _auth(gateway),
      ),
    );
    try {
      return DeviceWakeResult.fromJson(
        _jsonMap(response.data, 'Device wake response is invalid.'),
      );
    } on GatewayFailure {
      rethrow;
    } catch (_) {
      throw const GatewayFailure(
        'Device wake response is invalid.',
        code: 'invalid_api',
      );
    }
  }

  Options _auth(Gateway gateway) =>
      Options(headers: {'Authorization': 'Bearer ${gateway.apiToken}'});

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _mapError(error, healthCheck: false);
    }
  }

  GatewayFailure _mapError(DioException error, {required bool healthCheck}) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final apiCode = body is Map<String, dynamic> && body['error'] is Map
        ? (body['error'] as Map)['code'] as String?
        : null;
    if (apiCode == 'duplicate_device') {
      return GatewayFailure(
        'A device with this MAC address already exists.',
        code: apiCode,
      );
    }
    if (apiCode == 'validation_failed') {
      return GatewayFailure('Device details were rejected.', code: apiCode);
    }
    if (apiCode == 'device_not_found') {
      return GatewayFailure('Device was not found.', code: apiCode);
    }
    if (apiCode == 'bad_request') {
      return const GatewayFailure(
        'Gateway rejected the device action.',
        code: 'bad_request',
      );
    }
    if (apiCode == 'discovery_timeout') {
      return const GatewayFailure(
        'Device discovery timed out.',
        code: 'discovery_timeout',
      );
    }
    if (apiCode == 'invalid_json') {
      return const GatewayFailure(
        'Gateway rejected the request data.',
        code: 'bad_request',
      );
    }
    if (apiCode == 'internal_error') {
      return const GatewayFailure(
        'Gateway server error.',
        code: 'server_error',
      );
    }
    if (status == 401) {
      return const GatewayFailure(
        'API token is invalid.',
        code: 'unauthorized',
      );
    }
    if (status == 404) {
      return const GatewayFailure(
        'Gateway endpoint was not found.',
        code: 'not_found',
      );
    }
    if (status != null && status >= 400 && status < 500) {
      return GatewayFailure(
        healthCheck
            ? 'Gateway URL was rejected.'
            : 'Gateway rejected the request.',
        code: 'bad_request',
      );
    }
    if (status != null && status >= 500) {
      return const GatewayFailure(
        'Gateway server error.',
        code: 'server_error',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const GatewayFailure(
        'Gateway request timed out.',
        code: 'timeout',
      );
    }
    return GatewayFailure(
      healthCheck
          ? 'Gateway cannot be reached.'
          : 'Gateway could not process the request.',
      code: 'network_error',
    );
  }

  String _safeError(DioException error) => error.response?.statusCode == null
      ? error.type.name
      : 'HTTP ${error.response?.statusCode}';

  Map<String, dynamic> _jsonMap(Object? value, String message) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw GatewayFailure(message, code: 'invalid_api');
  }

  Map<String, dynamic> _diagnosticsJson(Object? value) {
    final json = _jsonMap(value, 'Gateway diagnostics response is invalid.');
    if (json['thermal'] is! Map) {
      throw const GatewayFailure(
        'Gateway diagnostics response is invalid.',
        code: 'invalid_api',
      );
    }
    return json;
  }
}
