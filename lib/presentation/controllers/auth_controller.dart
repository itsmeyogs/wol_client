import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_mode.dart';
import '../../core/logging/app_logger.dart';
import '../../core/auth/google_windows_sign_in.dart';

class AuthController extends GetxController {
  AuthController({FirebaseAuth? auth, SharedPreferences? preferences})
    : _auth = auth,
      _preferences = preferences;

  static const _guestKey = 'guest_mode';
  final FirebaseAuth? _auth;
  SharedPreferences? _preferences;
  final mode = AuthMode.loading.obs;
  final error = RxnString();
  final isBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<void> restoreSession() async {
    try {
      final guest = (await _prefs).getBool(_guestKey) == true;
      final auth = _auth;
      if (auth == null) {
        error.value = 'Firebase is unavailable. Check the local configuration.';
        mode.value = guest ? AuthMode.guest : AuthMode.login;
        return;
      }
      final user = auth.currentUser;
      if (user != null) {
        mode.value = AuthMode.authenticated;
      } else if (guest) {
        mode.value = AuthMode.guest;
      } else {
        mode.value = AuthMode.login;
      }
    } on FirebaseAuthException catch (exception) {
      error.value = _message(exception);
      mode.value = AuthMode.unavailable;
    } catch (_) {
      error.value = 'Authentication could not be initialized.';
      mode.value = AuthMode.unavailable;
    }
  }

  Future<void> continueAsGuest() async {
    error.value = null;
    await (await _prefs).setBool(_guestKey, true);
    mode.value = AuthMode.guest;
  }

  Future<bool> signInEmail(String email, String password) async {
    return _run('email sign-in', () async {
      await (_auth?.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ) ??
          Future<void>.error('Firebase is unavailable.'));
      await (await _prefs).remove(_guestKey);
      mode.value = AuthMode.authenticated;
    });
  }

  Future<bool> registerEmail(String email, String password) async {
    return _run('account registration', () async {
      await (_auth?.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ) ??
          Future<void>.error('Firebase is unavailable.'));
      await (await _prefs).remove(_guestKey);
      await _auth?.signOut();
      mode.value = AuthMode.login;
    });
  }

  Future<bool> signInGoogle() async {
    return _run('Google sign-in', () async {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        await _signInGoogleWindows();
      } else if (kIsWeb) {
        await (_auth?.signInWithPopup(GoogleAuthProvider()) ??
            Future<UserCredential>.error('Firebase is unavailable.'));
      } else {
        await (_auth?.signInWithProvider(GoogleAuthProvider()) ??
            Future<UserCredential>.error('Firebase is unavailable.'));
      }
      await (await _prefs).remove(_guestKey);
      mode.value = AuthMode.authenticated;
    });
  }

  Future<void> signOut() async {
    await _auth?.signOut();
    mode.value = AuthMode.login;
  }

  Future<void> exitGuestMode() async {
    await (await _prefs).remove(_guestKey);
    await _auth?.signOut();
    mode.value = AuthMode.login;
  }

  Future<void> _signInGoogleWindows() async {
    final auth = _auth;
    if (auth == null) throw StateError('Firebase is unavailable.');
    final credential = await signInGoogleWindows(auth);
    if (credential == null) {
      throw StateError('Google sign-in was cancelled.');
    }
  }

  Future<bool> _run(String operation, Future<void> Function() action) async {
    if (isBusy.value) return false;
    isBusy.value = true;
    error.value = null;
    AppLogger.instance.debug('$operation started');
    try {
      await action();
      AppLogger.instance.info('$operation succeeded');
      return true;
    } on FirebaseAuthException catch (exception) {
      AppLogger.instance.warning(
        '$operation failed: FirebaseAuthException('
        'code=${exception.code}, message=${exception.message ?? 'none'})',
      );
      error.value = _message(exception, operation);
      return false;
    } catch (exception) {
      AppLogger.instance.warning(
        '$operation failed: ${exception is StateError ? exception.message : exception.runtimeType}',
      );
      error.value = 'Authentication could not be completed.';
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  static String _message(
    FirebaseAuthException exception, [
    String? operation,
  ]) => switch (exception.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email or password is incorrect.',
    'invalid-email' => 'Enter a valid email address.',
    'email-already-in-use' => 'An account already exists for this email.',
    'weak-password' => 'Choose a stronger password.',
    'too-many-requests' => 'Too many attempts. Try again later.',
    'operation-not-allowed' => 'This sign-in method is not enabled.',
    'unknown-error' when operation == 'Google sign-in' =>
      'Google sign-in failed on Windows. Check the Firebase OAuth configuration.',
    'account-exists-with-different-credential' =>
      'An account already exists with another sign-in method.',
    'user-disabled' => 'This account is disabled.',
    'network-request-failed' => 'Network connection failed.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' => 'Google sign-in was cancelled.',
    'unimplemented' => 'This sign-in method is not supported on this platform.',
    _ => 'Authentication could not be completed.',
  };
}
