import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication service abstraction.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user.
  User? get currentUser => _auth.currentUser;

  /// Whether user is logged in.
  bool get isLoggedIn => _auth.currentUser != null;

  /// Get Firebase ID token for API calls.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await _auth.currentUser?.getIdToken(forceRefresh);
  }

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (displayName != null) {
      await credential.user?.updateDisplayName(displayName);
    }

    return credential;
  }

  /// Sign in with Google.
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final GoogleSignInClientAuthorization? authZ =
        await googleUser.authorizationClient.authorizationForScopes([]);

    final credential = GoogleAuthProvider.credential(
      accessToken: authZ?.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update password (requires recent auth).
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  /// Sign out.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}

/// Custom exception for Firebase Auth errors
class FirebaseAuthException implements Exception {
  final String code;
  final String message;

  FirebaseAuthException({required this.code, required this.message});

  @override
  String toString() => 'FirebaseAuthException($code): $message';
}
