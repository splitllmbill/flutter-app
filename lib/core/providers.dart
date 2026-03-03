import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';

/// Auth service singleton provider.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// API client provider (depends on auth service).
final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiClient(authService: authService);
});

/// Firebase auth state stream.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Whether the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (user) => user != null) ?? false;
});
