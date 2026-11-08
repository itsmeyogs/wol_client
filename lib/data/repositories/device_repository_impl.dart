import '../../core/network/dio_client.dart';
import '../../data/models/device.dart';
import '../../data/models/gateway.dart';
import '../../domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({DioClient? client})
    : _client = client ?? DioClient.instance;
  final DioClient _client;

  @override
  Future<List<Device>> getAll(Gateway gateway) => _client.getDevices(gateway);

  @override
  Future<Device> getById(Gateway gateway, int id) =>
      _client.getDevice(gateway, id);

  @override
  Future<Device> save(Gateway gateway, Device device) =>
      _client.saveDevice(gateway, device);

  @override
  Future<void> delete(Gateway gateway, int id) =>
      _client.deleteDevice(gateway, id);

  @override
  Future<List<DiscoveryDevice>> discover(Gateway gateway) =>
      _client.discoverDevices(gateway);

  @override
  Future<DeviceStatusResult> getStatus(Gateway gateway, int id) =>
      _client.getDeviceStatus(gateway, id);

  @override
  Future<DeviceWakeResult> wake(Gateway gateway, int id) =>
      _client.wakeDevice(gateway, id);
}
