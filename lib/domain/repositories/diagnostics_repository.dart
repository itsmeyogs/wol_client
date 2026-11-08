import '../../data/models/gateway.dart';
import '../../data/models/gateway_diagnostics.dart';

abstract class DiagnosticsRepository {
  Future<GatewayDiagnostics> get(Gateway gateway);
}
