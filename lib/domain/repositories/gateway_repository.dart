import '../../data/models/gateway.dart';

abstract class GatewayRepository {
  Future<List<Gateway>> getAll();
  Future<Gateway> save(Gateway gateway);
  Future<void> delete(int id);
}
