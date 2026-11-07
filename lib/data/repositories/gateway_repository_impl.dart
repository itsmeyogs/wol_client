import '../datasources/gateway_local_data_source.dart';
import '../models/gateway.dart';
import '../../domain/repositories/gateway_repository.dart';

class GatewayRepositoryImpl implements GatewayRepository {
  GatewayRepositoryImpl({GatewayLocalDataSource? local})
    : _local = local ?? GatewayLocalDataSource();
  final GatewayLocalDataSource _local;
  @override
  Future<List<Gateway>> getAll() => _local.getAll();
  @override
  Future<Gateway> save(Gateway gateway) =>
      gateway.id == null ? _local.insert(gateway) : _local.update(gateway);

  @override
  Future<void> delete(int id) => _local.delete(id);
}
