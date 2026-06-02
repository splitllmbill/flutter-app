import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/router.dart';
import 'core/utils/app_theme.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SplitLLMApp extends ConsumerStatefulWidget {
  const SplitLLMApp({super.key});

  @override
  ConsumerState<SplitLLMApp> createState() => _SplitLLMAppState();
}

class _SplitLLMAppState extends ConsumerState<SplitLLMApp> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        // When recovering password, the user is signed in and should be redirected to the account screen
        // to update their password. We wait for a frame to let GoRouter finish its initial redirect.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(routerProvider).go('/user-account');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SplitLLM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
