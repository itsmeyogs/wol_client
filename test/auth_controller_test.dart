import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wol_client/core/auth/auth_mode.dart';
import 'package:wol_client/core/auth/auth_service.dart';
import 'package:wol_client/presentation/controllers/auth_session_controller.dart';

void main() {
  test('restores saved guest mode without Firebase', () async {
    SharedPreferences.setMockInitialValues({'guest_mode': true});
    final preferences = await SharedPreferences.getInstance();
    final controller = AuthSessionController(
      AuthService(preferences: preferences),
    );

    await controller.restoreSession();

    expect(controller.mode.value, AuthMode.guest);
  });

  test('shows login when no guest mode or Firebase session exists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AuthSessionController(
      AuthService(preferences: preferences),
    );

    await controller.restoreSession();

    expect(controller.mode.value, AuthMode.login);
  });

  test('requires Firebase for registration', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = AuthService(preferences: preferences);
    final controller = AuthSessionController(service);

    final registered = await service.registerEmail(
      'user@example.com',
      'password',
    );

    expect(registered, isFalse);
    expect(controller.mode.value, AuthMode.loading);
    expect(service.lastError, 'Authentication could not be completed.');
  });
}
