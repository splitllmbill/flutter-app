import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/constants.dart';
import 'app.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

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
  usePathUrlStrategy();

  runApp(
    const ProviderScope(
      child: SplitLLMApp(),
    ),
  );
}
