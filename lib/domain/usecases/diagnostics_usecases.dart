import '../../data/models/gateway.dart';
import '../../data/models/gateway_diagnostics.dart';
import '../repositories/diagnostics_repository.dart';

class GetDiagnostics {
  const GetDiagnostics(this._repository);

  final DiagnosticsRepository _repository;

  Future<GatewayDiagnostics> call(Gateway gateway) => _repository.get(gateway);
}
