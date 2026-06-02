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

/// Auth state stream.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Whether the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (user) => user != null) ?? false;
});

/// Fetch user account from backend (including role).
final userAccountProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final isAuth = ref.watch(isAuthenticatedProvider);
  if (!isAuth) return null;
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/db/user/account');
    return res.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});
