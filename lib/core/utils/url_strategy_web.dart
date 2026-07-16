import 'package:flutter_web_plugins/url_strategy.dart';

/// Use path URLs (no `#`) so the router doesn't conflict with Supabase deep
/// link hashes. Web-only counterpart of `url_strategy_stub.dart`.
void configureUrlStrategy() {
  usePathUrlStrategy();
}
