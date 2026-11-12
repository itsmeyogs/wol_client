import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import 'google_windows_sign_in.dart';

/// Owns all Firebase authentication operations.
///
/// Page controllers keep their own loading/error state; this service only
/// performs the operation and exposes [lastError] for the caller to surface.
class AuthService {
  // ignore: prefer_initializing_formals
  AuthService({FirebaseAuth? auth, SharedPreferences? preferences})
    : _auth = auth, // ignore: prefer_initializing_formals
      _preferences = preferences; // ignore: prefer_initializing_formals

  static const guestKey = 'guest_mode';

  final FirebaseAuth? _auth;
  SharedPreferences? _preferences;  bool _busy = false;
  String? lastError;
  bool verificationRequired = false;
  AuthCredential? _pendingGoogleCredential;
  String? _pendingGoogleEmail;
  DateTime? _lastVerificationSent;

  FirebaseAuth? get auth => _auth;
  bool get available => _auth != null;
  User? get currentUser => _auth?.currentUser;
  bool get needsGoogleLinkPassword => _pendingGoogleCredential != null;
  String? get pendingGoogleEmail => _pendingGoogleEmail;
  bool get canSetPassword =>
      currentUser?.providerData.any((p) => p.providerId == 'google.com') ==
          true &&
      currentUser?.providerData.any((p) => p.providerId == 'password') != true;

  bool needsEmailVerification(User? user) =>
      user?.emailVerified == false &&
      user?.providerData.any((p) => p.providerId == 'password') == true &&
      user?.providerData.any((p) => p.providerId == 'google.com') != true;

  bool needsGoogleTrust(User? user) =>
      user?.providerData.any((p) => p.providerId == 'google.com') == true;

  Future<SharedPreferences> get preferences async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<SharedPreferences> get _prefs => preferences;

  Future<bool> signInEmail(String email, String password) =>
      _run('email sign-in', () async {
        final result = await (_auth?.signInWithEmailAndPassword(
              email: email.trim(),
              password: password,
            ) ??
            Future<UserCredential>.error('Firebase is unavailable.'));
        if (result.user?.emailVerified == false &&
            !needsGoogleTrust(result.user)) {
          verificationRequired = true;
          throw StateError('Verify your email before continuing.');
        }
        await _clearGuest();
      });

  Future<bool> registerEmail(String email, String password) =>
      _run('account registration', () async {
        final result = await (_auth?.createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            ) ??
            Future<UserCredential>.error('Firebase is unavailable.'));
        await result.user?.sendEmailVerification();
        await _clearGuest();
        await _auth?.signOut();
      });

  Future<bool> registerEmailFromSettings(String email, String password) =>
      _run('settings account registration', () async {
        final result = await (_auth?.createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            ) ??
            Future<UserCredential>.error('Firebase is unavailable.'));
        await result.user?.sendEmailVerification();
        await _clearGuest();
      });

  Future<bool> signInGoogle() => _run('Google sign-in', () async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final auth = _auth;
      if (auth == null) throw StateError('Firebase is unavailable.');
      final credential = await signInGoogleWindows(auth);
      if (credential == null) {
        throw StateError('Google sign-in was cancelled.');
      }
    } else if (kIsWeb) {
      await (_auth?.signInWithPopup(GoogleAuthProvider()) ??
          Future<UserCredential>.error('Firebase is unavailable.'));
    } else {
      await (_auth?.signInWithProvider(GoogleAuthProvider()) ??
          Future<UserCredential>.error('Firebase is unavailable.'));
    }
    await _clearGuest();
  });

  Future<bool> completeGoogleLink(String password) async {
    final auth = _auth;
    final credential = _pendingGoogleCredential;
    if (auth == null || credential == null) return false;
    return _run('Google account linking', () async {
      final targetEmail = _pendingGoogleEmail;
      if (targetEmail == null) {
        throw StateError('Google account email is unavailable.');
      }
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
      await _clearGuest();
    });
  }

  Future<bool> resendVerificationEmail() async {
    final user = currentUser;
    if (user == null) {
      lastError = 'Sign in before requesting a verification email.';
      return false;
    }
    final lastSent = _lastVerificationSent;
    if (lastSent != null &&
        DateTime.now().difference(lastSent).inSeconds < 60) {
      lastError = 'Wait before requesting another verification email.';
      return false;
    }
    return _run('verification email resend', () async {
      await user.sendEmailVerification();
      _lastVerificationSent = DateTime.now();
    });
  }

  Future<bool> checkEmailVerification() async {
    final user = currentUser;
    if (user == null) return false;
    await user.reload();
    if (currentUser?.emailVerified != true) {
      lastError = 'Email is not verified yet. Check your inbox and spam folder.';
      return false;
    }
    lastError = null;
    await _clearGuest();
    return true;
  }

  Future<bool> linkEmailPassword(String password) =>
      _run('email provider linking', () async {
        final user = currentUser;
        if (user == null) {
          throw StateError('Sign in before linking an account.');
        }
        await user.linkWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      });

  Future<bool> changeEmailPassword(String password, String currentPassword) =>
      _run('password change', () async {
        final user = currentUser;
        final email = user?.email;
        if (user == null || email == null) {
          throw StateError('Sign in with email and password first.');
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: email,
            password: currentPassword,
          ),
        );
        await user.updatePassword(password);
      });

  /// Reauthenticates the current user before a destructive operation.
  Future<bool> reauthenticate({String? password}) =>
      _run('account reauthentication', () async {
        final user = currentUser;
        if (user == null) {
          throw StateError('Sign in before continuing.');
        }
        final hasPassword = user.providerData.any(
          (p) => p.providerId == 'password',
        );
        final hasGoogle = user.providerData.any(
          (p) => p.providerId == 'google.com',
        );
        if (hasPassword && !hasGoogle) {
          final email = user.email;
          if (email == null || password == null || password.isEmpty) {
            throw StateError('Enter your current password to continue.');
          }
          await user.reauthenticateWithCredential(
            EmailAuthProvider.credential(email: email, password: password),
          );
        } else if (hasGoogle) {
          final credential = await _googleCredential();
          if (credential == null) {
            throw StateError('Google reauthentication was cancelled.');
          }
          await user.reauthenticateWithCredential(credential);
        } else {
          throw StateError('Reauthenticate with your sign-in provider first.');
        }
      });

  Future<bool> deleteCurrentUser() => _run('account deletion', () async {
    final user = currentUser;
    if (user == null) throw StateError('Sign in before deleting your account.');
    await user.delete();
    await _clearGuest();
  });

  Future<void> signOut() async {
    await _auth?.signOut();
    lastError = null;
  }

  Future<void> signOutUnverified() async {
    await _auth?.signOut();
    lastError = null;
  }

  Future<AuthCredential?> _googleCredential() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return getGoogleCredentialWindows();
    }
    final auth = _auth;
    if (auth == null) throw StateError('Firebase is unavailable.');
    return kIsWeb
        ? auth
              .signInWithPopup(GoogleAuthProvider())
              .then((value) => value.credential)
        : auth
              .signInWithProvider(GoogleAuthProvider())
              .then((value) => value.credential);
  }

  Future<void> _clearGuest() async => (await _prefs).remove(guestKey);

  Future<bool> _run(String operation, Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    lastError = null;
    verificationRequired = false;
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
      lastError = message(exception, operation);
      return false;
    } on StateError catch (exception) {
      lastError = exception.message;
      return false;
    } on PlatformException catch (exception, stackTrace) {
      AppLogger.instance.warning(
        '$operation failed: PlatformException(code=${exception.code})',
        exception,
        stackTrace,
      );
      lastError = exception.message ?? 'Authentication failed.';
      return false;
    } catch (exception, stackTrace) {
      AppLogger.instance.warning(
        '$operation failed: ${exception.runtimeType}',
        exception,
        stackTrace,
      );
      lastError = 'Authentication could not be completed.';
      return false;
    } finally {
      _busy = false;
    }
  }

  static String message(FirebaseAuthException exception, [String? operation]) =>
      switch (exception.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Email or password is incorrect.',
        'invalid-email' => 'Enter a valid email address.',
        'email-already-in-use' => 'An account already exists for this email.',
        'credential-already-in-use' ||
        'account-exists-with-different-credential' =>
          'This provider belongs to another account. Sign in to that account first; accounts cannot be merged automatically.',
        'provider-already-linked' => 'This sign-in method is already linked.',
        'weak-password' => 'Choose a stronger password.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'operation-not-allowed' => 'This sign-in method is not enabled.',
        'unknown-error' when operation == 'Google sign-in' =>
          'Google sign-in failed on Windows. Check the Firebase OAuth configuration.',
        'user-disabled' => 'This account is disabled.',
        'unauthorized-domain' => 'Domain is not authorized in Firebase Console.',
        'network-request-failed' => 'Network connection failed.',
        'popup-closed-by-user' ||
        'cancelled-popup-request' => 'Google sign-in was cancelled.',
        'unimplemented' =>
          'This sign-in method is not supported on this platform.',
        _ => 'Authentication could not be completed.',
      };
}
