import '../../data/models/device.dart';
import '../../data/models/gateway.dart';

abstract class DeviceRepository {
  Future<List<Device>> getAll(Gateway gateway);
  Future<Device> save(Gateway gateway, Device device);
  Future<void> delete(Gateway gateway, int id);
  Future<List<DiscoveryDevice>> discover(Gateway gateway);
}
