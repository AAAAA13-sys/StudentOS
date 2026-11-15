/// Build-time configuration.
///
/// The app only ever knows the gateway base URL. Override it with
/// `--dart-define=API_BASE_URL=http://<host>:8000`.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
