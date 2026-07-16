import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/constants.dart';
import 'app.dart';

// Web-only URL strategy; the stub is a no-op on Android/iOS where
// package:flutter_web_plugins does not compile.
import 'core/utils/url_strategy_stub.dart'
    if (dart.library.js_interop) 'core/utils/url_strategy_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load runtime config from .env. Optional: if absent, AppConstants falls back
  // to --dart-define values and then to built-in defaults.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env bundled — fall back to --dart-define / defaults.
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Use path URL strategy so flutter router doesn't conflict with Supabase deep link hashes
  configureUrlStrategy();

  // Phone-sized devices are portrait-only (matches the web manifest); tablets
  // keep free rotation for the wide layouts.
  if (!kIsWeb) {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
    if (shortestSide < 600) {
      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      );
    }

    // Draw behind transparent system bars on every OS version (Android 15+
    // forces this anyway); screens keep content clear of them via SafeArea.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android: light icons
        statusBarBrightness: Brightness.dark, // iOS: dark bg → light content
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  runApp(
    const ProviderScope(
      child: SplitLLMApp(),
    ),
  );
}
