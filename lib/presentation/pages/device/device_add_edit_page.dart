import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../../core/errors/gateway_failure.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../data/models/device.dart';
import '../../controllers/device_controller.dart';

class DeviceAddEditPage extends StatefulWidget {
  const DeviceAddEditPage({super.key, this.device, this.discovery});
  final Device? device;
  final DiscoveryDevice? discovery;
  @override
  State<DeviceAddEditPage> createState() => _DeviceAddEditPageState();
}

class _DeviceAddEditPageState extends State<DeviceAddEditPage> {
  late final TextEditingController _name;
  late final TextEditingController _ip;
  late final TextEditingController _mac;
  late final TextEditingController _broadcast;
  late final TextEditingController _wolPort;
  late final TextEditingController _statusPort;
  late String _method;

  @override
  void initState() {
    super.initState();
    final device = widget.device;
    final discovery = widget.discovery;
    _name = TextEditingController(
      text: device?.name ?? discovery?.hostName ?? '',
    );
    _ip = TextEditingController(
      text: device?.ipAddress ?? discovery?.ipAddress ?? '',
    );
    _mac = TextEditingController(
      text: device?.macAddress ?? discovery?.macAddress ?? '',
    );
    _broadcast = TextEditingController(
      text: device?.broadcastAddress ?? '255.255.255.255',
    );
    _wolPort = TextEditingController(text: '${device?.wolPort ?? 9}');
    _statusPort = TextEditingController(
      text: '${device?.statusCheckPort ?? 3389}',
    );
    _method = device?.statusCheckMethod ?? 'ICMP_AND_TCP';
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _ip,
      _mac,
      _broadcast,
      _wolPort,
      _statusPort,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final controller = Get.find<DeviceController>();
    final edit = widget.device != null;
    try {
      await controller.saveDevice(
        id: widget.device?.id,
        name: _name.text,
        ipAddress: _ip.text,
        macAddress: _mac.text,
        broadcastAddress: _broadcast.text,
        wolPort: _wolPort.text,
        statusCheckMethod: _method,
        statusCheckPort: _statusPort.text,
      );
      if (mounted) Get.back(result: edit ? 'updated' : 'added');
    } on GatewayFailure catch (failure) {
      AppSnackbar.error(failure.message);
    } catch (_) {
      AppSnackbar.error('Device could not be saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.device != null;
    final controller = Get.find<DeviceController>();
    return Scaffold(
      appBar: AppBar(title: Text(edit ? 'Edit device' : 'Add device')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              _field('Name', _name, 'Office PC'),
              _field('IP address', _ip, '192.168.1.20', decimal: true),
              _field('MAC address', _mac, 'AA:BB:CC:DD:EE:FF'),
              _field(
                'Broadcast address',
                _broadcast,
                '255.255.255.255',
                decimal: true,
              ),
              _field('WoL port', _wolPort, '9', numeric: true),
              const SizedBox(height: 4),
              Text(
                'Status check method',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              DropdownButtonFormField<String>(
                value: _method,
                items: const [
                  DropdownMenuItem(
                    value: 'ICMP_AND_TCP',
                    child: Text('ICMP and TCP'),
                  ),
                ],
                onChanged: (value) => setState(() => _method = value!),
              ),
              _field('Status check port', _statusPort, '3389', numeric: true),
              const SizedBox(height: 16),
              Obx(
                () => FilledButton.icon(
                  onPressed: controller.isSaving.value ? null : _save,
                  icon: controller.isSaving.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    controller.isSaving.value ? 'Saving...' : 'Save device',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    bool numeric = false,
    bool decimal = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: numeric || decimal
              ? TextInputType.numberWithOptions(decimal: decimal)
              : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : null,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    ),
  );
}
