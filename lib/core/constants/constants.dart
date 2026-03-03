/// Constants used throughout the application.
class AppConstants {
  AppConstants._();

  /// API base URL, injected via --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  /// App name
  static const String appName = 'SplitLLM';

  /// Date formats
  static const String dateFormatShort = 'dd MMM yyyy';
  static const String dateFormatTransaction = 'dd MMM';
}
