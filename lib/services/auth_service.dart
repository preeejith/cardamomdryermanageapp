import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user data with proper error handling
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? user = currentUser;
      if (user == null) return null;

      // Add delay to ensure Firebase is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        print('User document does not exist for UID: ${user.uid}');
        return null;
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Sign in with email and password - FIXED
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      // Sign in
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        throw Exception('Login failed - no user returned');
      }

      // Wait a moment for Firebase to sync
      await Future.delayed(const Duration(milliseconds: 300));

      // Get user data
      return await getCurrentUserData();
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Sign up with email and password - FIXED
  Future<UserModel?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? ownerId,
  }) async {
    try {
      // Create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        throw Exception('User creation failed');
      }

      final userId = result.user!.uid;

      // Create user document in Firestore
      UserModel newUser = UserModel(
        uid: userId,
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        role: role,
        ownerId: ownerId ?? userId,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(newUser.toMap());

      // If dryer owner, create owner document
      if (role == 'dryer_owner') {
        await _firestore
            .collection('dryerOwners')
            .doc(userId)
            .set({
          'ownerName': name.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'address': '',
          'createdAt': FieldValue.serverTimestamp(),
          'subscriptionStatus': 'active',
        });
      }

      // Wait for Firestore to sync
      await Future.delayed(const Duration(milliseconds: 300));

      return newUser;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  // Sign in with phone number (OTP) - FIXED
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Error verifying phone number: $e');
      rethrow;
    }
  }

  // Sign in with OTP credential - FIXED
  Future<UserModel?> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      await _auth.signInWithCredential(credential);
      
      // Wait for Firebase to sync
      await Future.delayed(const Duration(milliseconds: 300));
      
      return await getCurrentUserData();
    } on FirebaseAuthException catch (e) {
      print('Phone sign-in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error signing in with phone: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      print('Password reset error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email.trim());
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }
}