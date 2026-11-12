import 'package:firebase_auth/firebase_auth.dart';

import 'google_windows_sign_in_stub.dart'
    if (dart.library.io) 'google_windows_sign_in_io.dart'
    as platform;

Future<UserCredential?> signInGoogleWindows(FirebaseAuth auth) =>
    platform.signInGoogleWindows(auth);

Future<AuthCredential?> getGoogleCredentialWindows() =>
    platform.getGoogleCredentialWindows();
