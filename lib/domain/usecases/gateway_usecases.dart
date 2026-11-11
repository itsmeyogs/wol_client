import '../../data/models/gateway.dart';
import '../repositories/gateway_repository.dart';

class GetGateways {
  const GetGateways(this._repository);
  final GatewayRepository _repository;
  Future<List<Gateway>> call() => _repository.getAll();
}

class SaveGateway {
  const SaveGateway(this._repository);
  final GatewayRepository _repository;
  Future<Gateway> call(Gateway gateway) => _repository.save(gateway);
}

class DeleteGateway {
  const DeleteGateway(this._repository);
  final GatewayRepository _repository;
  Future<void> call(int id) => _repository.delete(id);
}

class ClearLocalGateways {
  const ClearLocalGateways(this._repository);
  final GatewayRepository _repository;
  Future<void> call() => _repository.clearLocal();
}
