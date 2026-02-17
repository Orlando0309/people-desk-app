/// Central app configuration.
///
/// Set API base URL at runtime via:
/// `--dart-define=PEOPLE_DESK_API_BASE_URL=http://.../api/v1`
///
/// Note: on Android emulator, `localhost` refers to the emulator itself.
/// Use `http://10.0.2.2:8080/api/v1` to reach your machine.
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'PEOPLE_DESK_API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// When enabled, the app uses in-memory mock responses instead of making
  /// network calls.
  ///
  /// Override at runtime via:
  /// `--dart-define=PEOPLE_DESK_USE_MOCK=false`
  static const useMock = bool.fromEnvironment('PEOPLE_DESK_USE_MOCK', defaultValue: true);
}
