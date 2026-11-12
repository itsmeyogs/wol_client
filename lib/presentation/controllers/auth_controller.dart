import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_mode.dart';
import '../../core/logging/app_logger.dart';
import '../../core/auth/google_windows_sign_in.dart';
import 'gateway_sync_controller.dart';
import '../../core/ui/app_snackbar.dart';
import 'gateway_controller.dart';

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
  User? get currentUser => _auth?.currentUser;
  AuthCredential? _pendingGoogleCredential;
  bool get needsGoogleLinkPassword => _pendingGoogleCredential != null;
  bool get needsEmailVerification =>
      _auth?.currentUser?.emailVerified == false &&
      _auth?.currentUser?.providerData.any((p) => p.providerId == 'password') ==
          true &&
      _auth?.currentUser?.providerData.any(
            (p) => p.providerId == 'google.com',
          ) !=
          true;
  DateTime? _lastVerificationSent;
  bool get canSetPassword =>
      _auth?.currentUser?.providerData.any(
            (provider) => provider.providerId == 'google.com',
          ) ==
          true &&
      _auth?.currentUser?.providerData.any(
            (provider) => provider.providerId == 'password',
          ) !=
          true;

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
        await user.reload();
        if (needsEmailVerification) {
          mode.value = AuthMode.verification;
          return;
        }
        mode.value = AuthMode.authenticated;
        _syncGateways();
      } else if (guest) {
        mode.value = AuthMode.guest;
      } else {
        mode.value = AuthMode.login;
      }
    } on FirebaseAuthException catch (exception) {
      AppLogger.instance.error(
        'Firebase auth restore failed: code=${exception.code}',
        exception,
        exception.stackTrace,
      );
      error.value = _message(exception);
      AppSnackbar.error(error.value!);
      mode.value = AuthMode.unavailable;
    } catch (exception, stackTrace) {
      AppLogger.instance.error(
        'Firebase auth restore failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      error.value = 'Authentication could not be initialized.';
      AppSnackbar.error(error.value!);
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
      final result =
          await (_auth?.signInWithEmailAndPassword(
                email: email.trim(),
                password: password,
              ) ??
              Future<UserCredential>.error('Firebase is unavailable.'));
      if (result.user?.emailVerified == false &&
          !needsGoogleTrust(result.user)) {
        mode.value = AuthMode.verification;
        throw StateError('Verify your email before continuing.');
      }
      await (await _prefs).remove(_guestKey);
      mode.value = AuthMode.authenticated;
      _syncGateways();
    });
  }

  bool needsGoogleTrust(User? user) =>
      user?.providerData.any(
        (provider) => provider.providerId == 'google.com',
      ) ==
      true;

  Future<bool> registerEmail(String email, String password) async {
    return _run('account registration', () async {
      final result =
          await (_auth?.createUserWithEmailAndPassword(
                email: email.trim(),
                password: password,
              ) ??
              Future<UserCredential>.error('Firebase is unavailable.'));
      await result.user?.sendEmailVerification();
      await (await _prefs).remove(_guestKey);
      await _auth?.signOut();
      mode.value = AuthMode.login;
    });
  }

  Future<bool> resendVerificationEmail() async {
    final user = _auth?.currentUser;
    if (user == null) return false;
    final lastSent = _lastVerificationSent;
    if (lastSent != null &&
        DateTime.now().difference(lastSent).inSeconds < 60) {
      error.value = 'Wait before requesting another verification email.';
      return false;
    }
    return _run('verification email resend', () async {
      await user.sendEmailVerification();
      _lastVerificationSent = DateTime.now();
    });
  }

  Future<bool> checkEmailVerification() async {
    final user = _auth?.currentUser;
    if (user == null) return false;
    await user.reload();
    if (_auth?.currentUser?.emailVerified != true) {
      error.value =
          'Email is not verified yet. Check your inbox and spam folder.';
      return false;
    }
    error.value = null;
    mode.value = AuthMode.authenticated;
    await (await _prefs).remove(_guestKey);
    _syncGateways();
    return true;
  }

  Future<void> signOutUnverified() async {
    await _auth?.signOut();
    error.value = null;
    mode.value = AuthMode.login;
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
      _syncGateways();
    });
  }

  Future<bool> completeGoogleLink(String password) async {
    final auth = _auth;
    final credential = _pendingGoogleCredential;
    if (auth == null || credential == null) return false;
    return _run('Google account linking', () async {
      // Sign into the verified existing password account, then attach Google.
      final targetEmail = _pendingGoogleEmail;
      if (targetEmail == null)
        throw StateError('Google account email is unavailable.');
      final existing = await auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );
      if (existing.user?.emailVerified != true) {
        await existing.user?.sendEmailVerification();
        await auth.signOut();
        throw StateError(
          'Verify your email using the link we just sent, then try Google sign-in again.',
        );
      }
      await existing.user!.linkWithCredential(credential);
      _pendingGoogleCredential = null;
      _pendingGoogleEmail = null;
      await (await _prefs).remove(_guestKey);
      mode.value = AuthMode.authenticated;
      _syncGateways();
    });
  }

  String? _pendingGoogleEmail;

  Future<bool> linkEmailPassword(String password) async {
    return _run('email provider linking', () async {
      final user = _auth?.currentUser;
      if (user == null) throw StateError('Sign in before linking an account.');
      await user.linkWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    });
  }

  Future<bool> linkGoogle() async {
    return _run('Google provider linking', () async {
      final auth = _auth;
      final user = auth?.currentUser;
      if (auth == null || user == null) {
        throw StateError('Sign in before linking an account.');
      }
      final credential =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
          ? await getGoogleCredentialWindows()
          : kIsWeb
          ? (await auth.signInWithPopup(GoogleAuthProvider())).credential
          : (await auth.signInWithProvider(GoogleAuthProvider())).credential;
      if (credential == null) throw StateError('Google sign-in was cancelled.');
      await user.linkWithCredential(credential);
    });
  }

  Future<void> signOut() async {
    if (Get.isRegistered<GatewayController>()) {
      await Get.find<GatewayController>().clearLocalState();
    }
    await _auth?.signOut();
    mode.value = AuthMode.login;
  }

  void _syncGateways() {
    if (Get.isRegistered<GatewaySyncController>()) {
      Get.find<GatewaySyncController>().sync(silent: true);
    }
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
      if (operation == 'Google sign-in' &&
          exception.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = exception.credential;
        _pendingGoogleEmail = exception.email;
      }
      AppLogger.instance.warning(
        '$operation failed: FirebaseAuthException(code=${exception.code})',
        exception,
        exception.stackTrace,
      );
      error.value = _message(exception, operation);
      return false;
    } on StateError catch (exception) {
      error.value = exception.message;
      return false;
    } catch (exception, stackTrace) {
      AppLogger.instance.warning(
        '$operation failed: ${exception.runtimeType}',
        exception,
        stackTrace,
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
    'credential-already-in-use' || 'account-exists-with-different-credential' =>
      'This provider belongs to another account. Sign in to that account first; accounts cannot be merged automatically.',
    'provider-already-linked' => 'This sign-in method is already linked.',
    'weak-password' => 'Choose a stronger password.',
    'too-many-requests' => 'Too many attempts. Try again later.',
    'operation-not-allowed' => 'This sign-in method is not enabled.',
    'unknown-error' when operation == 'Google sign-in' =>
      'Google sign-in failed on Windows. Check the Firebase OAuth configuration.',
    'user-disabled' => 'This account is disabled.',
    'network-request-failed' => 'Network connection failed.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' => 'Google sign-in was cancelled.',
    'unimplemented' => 'This sign-in method is not supported on this platform.',
    _ => 'Authentication could not be completed.',
  };
}
