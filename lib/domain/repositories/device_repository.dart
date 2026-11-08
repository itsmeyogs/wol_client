import '../../data/models/device.dart';
import '../../data/models/gateway.dart';

abstract class DeviceRepository {
  Future<List<Device>> getAll(Gateway gateway);
  Future<Device> getById(Gateway gateway, int id);
  Future<Device> save(Gateway gateway, Device device);
  Future<void> delete(Gateway gateway, int id);
  Future<List<DiscoveryDevice>> discover(Gateway gateway);
  Future<DeviceStatusResult> getStatus(Gateway gateway, int id);
  Future<DeviceWakeResult> wake(Gateway gateway, int id);
}
