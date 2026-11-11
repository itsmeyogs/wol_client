import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

const _googleWebClientId =
    '225820838593-jtvtensnncee7rnm1lcli2ag8bkqjpq8.apps.googleusercontent.com';
const _windowsOAuthPort = 49152;

Future<UserCredential?> signInGoogleWindows(FirebaseAuth auth) async {
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    _windowsOAuthPort,
  );
  const redirectUri = 'http://localhost:49152';

  try {
    final targetUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': _googleWebClientId,
      'redirect_uri': redirectUri,
      'response_type': 'id_token token',
      'scope': 'openid profile email',
      'nonce': 'auth_nonce_${DateTime.now().millisecondsSinceEpoch}',
    });

    if (!await launchUrl(targetUrl, mode: LaunchMode.externalApplication)) {
      throw StateError('Failed to launch browser for authentication.');
    }

    String? accessToken;
    String? idToken;
    String? error;

    await for (final request in server.timeout(const Duration(minutes: 5))) {
      if (request.uri.path == '/auth_callback' && request.method == 'POST') {
        final body = await utf8.decoder.bind(request).join();
        final params = Uri.splitQueryString(body);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.add('Access-Control-Allow-Origin', '*')
          ..write('OK');
        await request.response.close();
        accessToken = params['access_token'];
        idToken = params['id_token'];
        error = params['error'];
        break;
      }

      if (request.method == 'GET') {
        final html = await rootBundle.loadString(
          'assets/html/oauth_callback.html',
        );
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(html);
      } else if (request.method == 'OPTIONS') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.add('Access-Control-Allow-Origin', '*')
          ..headers.add('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
          ..headers.add('Access-Control-Allow-Headers', '*');
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found');
      }
      await request.response.close();
    }

    if (error != null) throw StateError('Google authorization failed.');
    if (idToken == null || accessToken == null) {
      throw StateError('Google authorization returned no credential.');
    }

    return auth.signInWithCredential(
      GoogleAuthProvider.credential(accessToken: accessToken, idToken: idToken),
    );
  } on TimeoutException {
    return null;
  } finally {
    await server.close(force: true);
  }
}
