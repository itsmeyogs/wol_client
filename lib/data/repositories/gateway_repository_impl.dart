import '../../core/network/dio_client.dart';
import '../datasources/gateway_local_data_source.dart';
import '../models/gateway.dart';
import '../../domain/repositories/gateway_repository.dart';

class GatewayRepositoryImpl implements GatewayRepository {
  GatewayRepositoryImpl({GatewayLocalDataSource? local, DioClient? client})
    : _local = local ?? GatewayLocalDataSource(),
      _client = client ?? DioClient.instance;
  final GatewayLocalDataSource _local;
  final DioClient _client;
  @override
  Future<List<Gateway>> getAll() => _local.getAll();
  @override
  Future<Gateway> save(Gateway gateway) async {
    await _client.validateGateway(gateway);
    return gateway.id == null ? _local.insert(gateway) : _local.update(gateway);
  }

  @override
  Future<void> delete(int id) => _local.delete(id);
}
