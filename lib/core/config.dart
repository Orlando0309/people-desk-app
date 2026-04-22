import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Central app configuration.
///
/// Set API base URL at runtime via:
/// `--dart-define=PEOPLE_DESK_API_BASE_URL=http://.../api/v1`
///
/// Note: on Android emulator, `localhost` refers to the emulator itself.
/// Use `http://10.0.2.2:8080/api/v1` to reach your machine.
class AppConfig {
  static const _configuredBaseUrl = String.fromEnvironment(
    'PEOPLE_DESK_API_BASE_URL',
    defaultValue: '',
  );

  /// API base URL with automatic platform detection for Android emulator.
  /// Falls back to localhost for web/desktop/iOS simulator.
  static String get apiBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    // On Android emulator, use 10.0.2.2 to reach host machine
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  /// When enabled, the app uses in-memory mock responses instead of making
  /// network calls.
  ///
  /// Override at runtime via:
  /// `--dart-define=PEOPLE_DESK_USE_MOCK=true`
  static const useMock = bool.fromEnvironment('PEOPLE_DESK_USE_MOCK', defaultValue: false);
}