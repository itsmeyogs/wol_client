import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();
  static final instance = AppLogger._();
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  void debug(String message) {
    if (kDebugMode) _logger.d(message);
  }

  void info(String message) {
    if (kDebugMode) _logger.i(message);
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.w(_safe(message), error: _safe(error), stackTrace: stackTrace);
    }
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      kDebugMode
      ? _logger.e(_safe(message), error: _safe(error), stackTrace: stackTrace)
      : null;

  static String? _safe(Object? value) {
    if (value == null) return null;
    return value
        .toString()
        .replaceAll(
          RegExp(r'authorization[=: ]+bearer\s+[^,\s]+', caseSensitive: false),
          'Authorization: Bearer [REDACTED]',
        )
        .replaceAll(
          RegExp(
            r'(api[_-]?token|access[_-]?token|refresh[_-]?token)[=: ]+[^,\s]+',
            caseSensitive: false,
          ),
          '[REDACTED_TOKEN]',
        );
  }
}
