import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Constants used throughout the application.
///
/// Runtime configuration (Supabase, API base URL) is resolved at startup from,
/// in order of precedence:
///   1. the bundled `.env` file (loaded in `main()` via `flutter_dotenv`),
///   2. a compile-time `--dart-define=KEY=value`,
///   3. a built-in default (suitable for local development).
///
/// This means you can change Supabase / API settings by editing `.env` (or the
/// host's environment variables) without touching Dart code.
class AppConstants {
  AppConstants._();

  /// App name.
  static const String appName = 'SplitLLM';

  /// Reads [key] from `.env`, falling back to a `--dart-define` value, then to
  /// [fallback]. Safe to call even if `.env` was never loaded.
  static String _env(String key, String fromDefine, String fallback) {
    final fromFile = dotenv.maybeGet(key);
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    if (fromDefine.isNotEmpty) return fromDefine;
    return fallback;
  }

  // --dart-define fallbacks (compile-time). Empty unless explicitly provided.
  static const String _defineApiBaseUrl =
      String.fromEnvironment('API_BASE_URL');
  static const String _defineSupabaseUrl =
      String.fromEnvironment('SUPABASE_URL');
  static const String _defineSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Backend API base URL.
  static String get apiBaseUrl => _env('API_BASE_URL', _defineApiBaseUrl, '');

  /// Supabase project URL.
  static String get supabaseUrl => _env('SUPABASE_URL', _defineSupabaseUrl, '');

  /// Supabase publishable / anon key (public by design; protected by RLS).
  static String get supabaseAnonKey =>
      _env('SUPABASE_ANON_KEY', _defineSupabaseAnonKey, '');

  /// Date formats.
  static const String dateFormatShort = 'dd MMM yyyy';
  static const String dateFormatTransaction = 'dd MMM';
}
