import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/gateway_session_controller.dart';

class GatewayDashboardPage extends StatelessWidget {
  const GatewayDashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final gateway = Get.find<GatewaySessionController>().activeGateway.value;
    return Scaffold(
      appBar: AppBar(title: Text(gateway?.name ?? 'Gateway')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Gateway dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'One gateway, one workspace for your WoL devices.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connected gateway'),
                  SizedBox(height: 8),
                  Text('Device management is coming in the next checkpoint.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.link, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${gateway?.scheme}://${gateway?.baseUrl}/api/v1',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
