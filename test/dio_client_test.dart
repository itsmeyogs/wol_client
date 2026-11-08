import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wol_client/core/errors/gateway_failure.dart';
import 'package:wol_client/core/network/dio_client.dart';
import 'package:wol_client/data/models/gateway.dart';

void main() {
  final client = DioClient.instance;
  final gateway = Gateway(
    name: 'Test',
    scheme: 'http',
    baseUrl: 'gateway.test',
    apiToken: 'do-not-log',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('maps malformed device response to a safe API failure', () async {
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<String>(
          requestOptions: options,
          statusCode: 200,
          data: 'not-json',
        ),
      ),
    );
    client.dio.interceptors.add(interceptor);
    addTearDown(() => client.dio.interceptors.remove(interceptor));

    expect(
      () => client.getDevices(gateway),
      throwsA(
        isA<GatewayFailure>().having(
          (failure) => failure.code,
          'code',
          'invalid_api',
        ),
      ),
    );
  });

  test('maps discovery timeout without exposing response details', () async {
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          response: Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 504,
            data: {
              'error': {
                'code': 'discovery_timeout',
                'message': 'internal detail',
              },
            },
          ),
        ),
      ),
    );
    client.dio.interceptors.add(interceptor);
    addTearDown(() => client.dio.interceptors.remove(interceptor));

    expect(
      () => client.discoverDevices(gateway),
      throwsA(
        isA<GatewayFailure>()
            .having((failure) => failure.code, 'code', 'discovery_timeout')
            .having(
              (failure) => failure.message,
              'message',
              'Device discovery timed out.',
            ),
      ),
    );
  });

  test('maps server errors to a safe message', () async {
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          response: Response<String>(
            requestOptions: options,
            statusCode: 500,
            data: 'secret server body',
          ),
        ),
      ),
    );
    client.dio.interceptors.add(interceptor);
    addTearDown(() => client.dio.interceptors.remove(interceptor));

    expect(
      () => client.getDevices(gateway),
      throwsA(
        isA<GatewayFailure>()
            .having((failure) => failure.code, 'code', 'server_error')
            .having(
              (failure) => failure.message,
              'message',
              'Gateway server error.',
            ),
      ),
    );
  });
}
