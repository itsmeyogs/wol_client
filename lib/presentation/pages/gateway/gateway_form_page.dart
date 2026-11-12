import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../data/models/gateway.dart';
import '../../controllers/gateway_form_controller.dart';

class GatewayFormPage extends StatefulWidget {
  const GatewayFormPage({super.key, this.gateway});
  final Gateway? gateway;
  @override
  State<GatewayFormPage> createState() => _GatewayFormPageState();
}

class _GatewayFormPageState extends State<GatewayFormPage> {
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _token;
  late String _scheme;
  late final GatewayFormController controller;

  @override
  void initState() {
    super.initState();
    final gateway =
        widget.gateway ??
        (Get.arguments is Gateway ? Get.arguments as Gateway : null);
    _name = TextEditingController(text: gateway?.name);
    _baseUrl = TextEditingController(text: gateway?.baseUrl);
    _token = TextEditingController(text: gateway?.apiToken);
    _scheme = gateway?.scheme ?? 'https';
    controller = Get.put(GatewayFormController(gateway));
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _token.dispose();
    Get.delete<GatewayFormController>();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await controller.save(
      name: _name.text,
      scheme: _scheme,
      baseUrl: _baseUrl.text,
      apiToken: _token.text,
    );
    if (!mounted) return;
    if (!saved) {
      AppSnackbar.error(
        controller.error.value ?? 'Gateway could not be saved.',
      );
      return;
    }
    Navigator.of(context).pop(controller.isEdit ? 'updated' : 'added');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.gateway != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit gateway' : 'Add gateway')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              const SizedBox(height: 12),
              _createTextField(
                context: context,
                controller: _name,
                label: 'Name',
                hint: 'Office gateway',
              ),
              const SizedBox(height: 16),
              Text(
                'Scheme',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: 15),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('https://'),
                      value: 'https',
                      groupValue: _scheme,
                      onChanged: (value) => setState(() => _scheme = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('http://'),
                      value: 'http',
                      groupValue: _scheme,
                      onChanged: (value) => setState(() => _scheme = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _createTextField(
                context: context,
                controller: _baseUrl,
                label: 'Base URL',
                hint: 'gateway.example.com',
              ),
              const SizedBox(height: 16),
              _createTextField(
                context: context,
                controller: _token,
                label: 'API token',
                isObscure: true,
                helperText: 'Used only for authenticated gateway requests.',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 28),
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
                    controller.isSaving.value
                        ? 'Checking gateway...'
                        : 'Save gateway',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isObscure = false,
    String? helperText,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final textStyle = Theme.of(context).textTheme;
    final labelTextStyle = textStyle.labelLarge?.copyWith(fontSize: 15);
    final fieldTextStyle = textStyle.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelTextStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          style: fieldTextStyle,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
