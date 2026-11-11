import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wol_client/core/auth/auth_mode.dart';
import 'package:wol_client/presentation/controllers/auth_controller.dart';

void main() {
  test('restores saved guest mode without Firebase', () async {
    SharedPreferences.setMockInitialValues({'guest_mode': true});
    final preferences = await SharedPreferences.getInstance();
    final controller = AuthController(preferences: preferences);

    await controller.restoreSession();

    expect(controller.mode.value, AuthMode.guest);
  });

  test('shows login when no guest mode or Firebase session exists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AuthController(preferences: preferences);

    await controller.restoreSession();

    expect(controller.mode.value, AuthMode.login);
  });

  test('requires Firebase for registration', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AuthController(preferences: preferences);

    await controller.registerEmail('user@example.com', 'password');

    expect(controller.mode.value, AuthMode.loading);
    expect(controller.error.value, 'Authentication could not be completed.');
  });
}
