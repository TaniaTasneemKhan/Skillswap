import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth;
  AuthService(this._auth);

  /// "Remember me" (web only): keep the session after closing the browser,
  /// or end it with the tab. Mobile always keeps the session.
  Future<void> _persist(bool remember) async {
    if (!kIsWeb) return;
    try {
      await _auth.setPersistence(remember ? Persistence.LOCAL : Persistence.SESSION);
    } catch (_) {}
  }

  Future<UserCredential> signUp(String email, String password) async {
    await _persist(true);
    return _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> signIn(String email, String password, {bool remember = true}) async {
    await _persist(remember);
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  /// Turns Firebase errors into messages a user can act on.
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a bit and retry.';
      }
      return e.message ?? 'Authentication failed.';
    }
    return 'Something went wrong. Please try again.';
  }
}
