import '../../data/models/device.dart';
import '../../data/models/gateway.dart';
import '../repositories/device_repository.dart';

class GetDevices {
  const GetDevices(this._repository);
  final DeviceRepository _repository;
  Future<List<Device>> call(Gateway gateway) => _repository.getAll(gateway);
}

class GetDevice {
  const GetDevice(this._repository);
  final DeviceRepository _repository;
  Future<Device> call(Gateway gateway, int id) =>
      _repository.getById(gateway, id);
}

class SaveDevice {
  const SaveDevice(this._repository);
  final DeviceRepository _repository;
  Future<Device> call(Gateway gateway, Device device) =>
      _repository.save(gateway, device);
}

class DeleteDevice {
  const DeleteDevice(this._repository);
  final DeviceRepository _repository;
  Future<void> call(Gateway gateway, int id) => _repository.delete(gateway, id);
}

class DiscoverDevices {
  const DiscoverDevices(this._repository);
  final DeviceRepository _repository;
  Future<List<DiscoveryDevice>> call(Gateway gateway) =>
      _repository.discover(gateway);
}

class CheckDeviceStatus {
  const CheckDeviceStatus(this._repository);
  final DeviceRepository _repository;
  Future<DeviceStatusResult> call(Gateway gateway, int id) =>
      _repository.getStatus(gateway, id);
}

class WakeDevice {
  const WakeDevice(this._repository);
  final DeviceRepository _repository;
  Future<DeviceWakeResult> call(Gateway gateway, int id) =>
      _repository.wake(gateway, id);
}
