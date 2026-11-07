import 'package:get/get.dart';
import '../../data/models/gateway.dart';

class GatewaySessionController extends GetxController {
  final activeGateway = Rxn<Gateway>();
  void open(Gateway gateway) => activeGateway.value = gateway;
  void clear() => activeGateway.value = null;
}
