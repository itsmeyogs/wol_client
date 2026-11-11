import '../repositories/gateway_sync_repository.dart';

class SyncGateways {
  const SyncGateways(this._repository);
  final GatewaySyncRepository _repository;
  Future<void> call() => _repository.sync();
}
