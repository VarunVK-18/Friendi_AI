import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// NEW GoogleSignIn instance (v7+)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Auth state listener
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// EMAIL LOGIN
  Future<UserCredential> signInWithEmail(
      String email,
      String password,
      ) async {

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// EMAIL SIGNUP
  Future<UserCredential> signUpWithEmail(
      String email,
      String password,
      ) async {

    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// GOOGLE SIGN-IN (CORRECT FLOW FOR google_sign_in v7)
  Future<UserCredential> signInWithGoogle() async {

    try {

      /// REQUIRED initialization (v7 SDK requirement)
      await _googleSignIn.initialize();

      /// Opens Google account picker
      final GoogleSignInAccount googleUser =
      await _googleSignIn.authenticate();

      /// Get ID token
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception("Missing Google ID token");
      }

      /// Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      /// Firebase login
      return await _auth.signInWithCredential(
        credential,
      );

    } catch (e) {
      throw Exception("Google Sign-In failed: $e");
    }
  }

  /// LOGOUT
  Future<void> signOut() async {

    try {

      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

    } catch (e) {

      throw Exception("Sign out failed: $e");
    }
  }

  /// RESET PASSWORD EMAIL
  Future<void> sendPasswordResetEmail(
      String email,
      ) async {

    try {

      await _auth.sendPasswordResetEmail(
        email: email,
      );

    } on FirebaseAuthException catch (e) {

      throw Exception(e.message);
    }
  }

  /// UPDATE PROFILE
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {

    final user = _auth.currentUser;

    if (user == null) return;

    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }

    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }

    await user.reload();
  }

  /// UPDATE EMAIL
  Future<void> updateEmail(String newEmail) async {

    final user = _auth.currentUser;

    if (user == null) return;

    await user.verifyBeforeUpdateEmail(newEmail);
  }

  /// UPDATE PASSWORD
  Future<void> updatePassword(String newPassword) async {

    final user = _auth.currentUser;

    if (user == null) return;

    await user.updatePassword(newPassword);
  }

  /// DELETE ACCOUNT
  Future<void> deleteAccount() async {

    final user = _auth.currentUser;

    if (user == null) return;

    await user.delete();
  }

  /// REAUTHENTICATE USER
  Future<void> reauthenticateWithPassword(
      String password,
      ) async {

    final user = _auth.currentUser;

    if (user == null || user.email == null) return;

    final credential =
    EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(
      credential,
    );
  }
}