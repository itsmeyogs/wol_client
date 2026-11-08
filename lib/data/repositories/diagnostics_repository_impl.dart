import '../../core/network/dio_client.dart';
import '../../data/models/gateway.dart';
import '../../data/models/gateway_diagnostics.dart';
import '../../domain/repositories/diagnostics_repository.dart';

class DiagnosticsRepositoryImpl implements DiagnosticsRepository {
  DiagnosticsRepositoryImpl({DioClient? client})
    : _client = client ?? DioClient.instance;

  final DioClient _client;

  @override
  Future<GatewayDiagnostics> get(Gateway gateway) =>
      _client.getDiagnostics(gateway);
}
