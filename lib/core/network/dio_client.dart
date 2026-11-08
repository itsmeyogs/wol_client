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
      await dio.get(
        '${gateway.apiBaseUrl}/diagnostics',
        options: Options(
          headers: {'Authorization': 'Bearer ${gateway.apiToken}'},
        ),
      );
    } on DioException catch (error) {
      throw _mapError(error, healthCheck: false);
    }
  }

  Future<GatewayDiagnostics> getDiagnostics(Gateway gateway) async {
    final response = await _request(
      () =>
          dio.get('${gateway.apiBaseUrl}/diagnostics', options: _auth(gateway)),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const GatewayFailure(
        'Gateway diagnostics response is invalid.',
        code: 'invalid_api',
      );
    }
    return GatewayDiagnostics.fromJson(data);
  }

  Future<List<Device>> getDevices(Gateway gateway) async {
    final response = await _request(
      () => dio.get('${gateway.apiBaseUrl}/devices', options: _auth(gateway)),
    );
    return (response.data as List<dynamic>)
        .map((item) => Device.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Device> getDevice(Gateway gateway, int id) async {
    final response = await _request(
      () =>
          dio.get('${gateway.apiBaseUrl}/devices/$id', options: _auth(gateway)),
    );
    return Device.fromJson(response.data as Map<String, dynamic>);
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
    return Device.fromJson(response.data as Map<String, dynamic>);
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
    final devices =
        (response.data as Map<String, dynamic>)['devices'] as List<dynamic>?;
    return (devices ?? const [])
        .map((item) => DiscoveryDevice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DeviceStatusResult> getDeviceStatus(Gateway gateway, int id) async {
    final response = await _request(
      () => dio.get(
        '${gateway.apiBaseUrl}/devices/$id/status',
        options: _auth(gateway),
      ),
    );
    return DeviceStatusResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DeviceWakeResult> wakeDevice(Gateway gateway, int id) async {
    final response = await _request(
      () => dio.post(
        '${gateway.apiBaseUrl}/devices/$id/wake',
        options: _auth(gateway),
      ),
    );
    return DeviceWakeResult.fromJson(response.data as Map<String, dynamic>);
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
            : 'Gateway rejected the diagnostics request.',
        code: 'bad_request',
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
}
