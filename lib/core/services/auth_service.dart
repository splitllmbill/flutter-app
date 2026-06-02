import 'package:supabase_flutter/supabase_flutter.dart';

/// App user mapping
class AppUser {
  final String uid;
  final String email;
  final String? displayName;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  factory AppUser.fromSupabaseUser(User user) {
    return AppUser(
      uid: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
    );
  }
}

/// Supabase Authentication service abstraction.
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream of auth state changes.
  Stream<AppUser?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((event) {
      final session = event.session;
      if (session == null) {
        return null;
      }
      return AppUser.fromSupabaseUser(session.user);
    });
  }

  /// Current user.
  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    return user != null ? AppUser.fromSupabaseUser(user) : null;
  }

  /// Whether user is logged in.
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  /// Get Supabase JWT token for API calls.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;
    
    // In Supabase, we can use the access token directly as the JWT
    // If it's expired, the client usually auto-refreshes it.
    // We'll just return the session's access token.
    return session.accessToken;
  }

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'full_name': displayName} : null,
    );
  }

  /// Sign in with Google (OAuth).
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'http://localhost:8080', // Replace with your web url/app scheme
    );
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Update password (requires recent auth).
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Sign out.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

/// Custom exception mapping to old FirebaseAuthException so UI code still works
class FirebaseAuthException implements Exception {
  final String code;
  final String message;

  FirebaseAuthException({required this.code, required this.message});

  @override
  String toString() => 'FirebaseAuthException($code): $message';
}
