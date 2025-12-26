import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'auth_service.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hash password using SHA-256 (for simple implementation)
  /// In production, use bcrypt or Argon2 via Cloud Functions
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Login with Student ID and password
  static Future<void> loginWithStudentId(
    String studentId,
    String password,
  ) async {
    try {
      // Query user by studentId
      final userQuery = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Invalid Student ID');
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final userId = userDoc.id;

      // Verify password
      final passwordHash = _hashPassword(password);
      final storedHash = userData['passwordHash'] as String?;

      if (storedHash == null || storedHash != passwordHash) {
        throw Exception('Invalid password');
      }

      // Create a custom token using Firebase Admin SDK (via Cloud Function)
      // For now, we'll use email-based auth with internal email
      // OR use anonymous auth and link with custom claims

      // Option 1: Use email auth with internal email format
      // This is a workaround - ideally use Cloud Function for custom tokens
      final university = (userData['university'] as String? ?? 'university')
          .replaceAll(' ', '')
          .toLowerCase();
      final internalEmail = '$studentId@$university.internal';

      try {
        // Try to sign in with the internal email
        // Note: You need to create the user with this email format in Firebase Auth
        final credential = await _auth.signInWithEmailAndPassword(
          email: internalEmail,
          password: password,
        );

        // Store user data in AuthService
        final userDataForApp = {...userData, 'id': userId};
        await AuthService.setSession(credential.user!.uid, userDataForApp);
      } catch (e) {
        // If email auth fails, create account with internal email
        // This is for development - in production use Cloud Functions
        final credential = await _auth.createUserWithEmailAndPassword(
          email: internalEmail,
          password: password,
        );

        // Update user document with Firebase UID
        await _firestore.collection('users').doc(userId).update({
          'firebaseUid': credential.user!.uid,
        });

        final userDataForApp = {...userData, 'id': userId};
        await AuthService.setSession(credential.user!.uid, userDataForApp);
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Signup with Student ID and user information
  static Future<void> signupWithStudentId({
    required String studentId,
    required String password,
    required String name,
    required String email,
    required String university,
  }) async {
    try {
      // Hash password
      final passwordHash = _hashPassword(password);

      // Create internal email for Firebase Auth
      final internalEmail =
          '$studentId@${university.replaceAll(' ', '').toLowerCase()}.internal';

      UserCredential credential;
      try {
        // Create Firebase Auth user
        credential = await _auth.createUserWithEmailAndPassword(
          email: internalEmail,
          password: password,
        );
      } on FirebaseAuthException catch (authError) {
        if (authError.code == 'email-already-in-use') {
          // The Firebase Auth account exists but the Firestore profile might not.
          // Try to sign in and see whether a profile already exists.
          final existingCredential = await _auth.signInWithEmailAndPassword(
            email: internalEmail,
            password: password,
          );
          final existingUserId = existingCredential.user!.uid;
          final existingProfile = await _firestore
              .collection('users')
              .doc(existingUserId)
              .get();

          if (existingProfile.exists) {
            await _auth.signOut();
            throw Exception(
              'Student ID already registered. Please log in instead.',
            );
          }

          credential = existingCredential;
        } else {
          throw Exception('Signup failed: ${authError.message}');
        }
      }

      final userId = credential.user!.uid;

      // Re-check studentId uniqueness now that the user is authenticated
      final duplicateStudentId = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (duplicateStudentId.docs.isNotEmpty) {
        await credential.user!.delete();
        throw Exception('Student ID already registered');
      }

      // Create user document in Firestore
      final userData = {
        'id': userId,
        'studentId': studentId,
        'name': name,
        'email': email,
        'university': university,
        'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$studentId',
        'bio': '',
        'rating': 0.0,
        'followers': 0,
        'following': [],
        'savedPosts': [],
        'verified': false,
        'passwordHash': passwordHash,
        'firebaseUid': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(userData);

      // Store user data in AuthService
      await AuthService.setSession(userId, userData);
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  /// Logout current user
  static Future<void> logout() async {
    await _auth.signOut();
    await AuthService.clearSession();
  }

  /// Get current Firebase user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Listen to auth state changes
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
