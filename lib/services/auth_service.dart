import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static String? _sessionToken;
  static Map<String, dynamic>? _user;

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current session (check Firebase Auth first)
  static Future<Map<String, dynamic>?> getSession() async {
    // Check Firebase Auth first
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      // Load user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (userDoc.exists) {
        _user = userDoc.data();
        _sessionToken = firebaseUser.uid;
        return {'token': _sessionToken, 'user': _user};
      }
    }

    // Fallback to stored session
    return _sessionToken != null
        ? {'token': _sessionToken, 'user': _user}
        : null;
  }

  static Future<void> setSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    _sessionToken = token;
    _user = user;
  }

  static Future<void> clearSession() async {
    _sessionToken = null;
    _user = null;
  }

  static String? getToken() => _sessionToken ?? _auth.currentUser?.uid;
  static Map<String, dynamic>? getUser() => _user;

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _auth.currentUser != null || _sessionToken != null;
  }
}
