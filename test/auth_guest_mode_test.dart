import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wol_client/core/auth/auth_mode.dart';
import 'package:wol_client/presentation/controllers/auth_controller.dart';

void main() {
  test('exit guest mode clears only the guest flag', () async {
    SharedPreferences.setMockInitialValues({'guest_mode': true});
    final preferences = await SharedPreferences.getInstance();
    final controller = AuthController(preferences: preferences);

    await controller.exitGuestMode();

    expect(controller.mode.value, AuthMode.login);
    expect(preferences.getBool('guest_mode'), isNull);
  });
}
