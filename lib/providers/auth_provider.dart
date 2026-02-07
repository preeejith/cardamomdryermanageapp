import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isDryerOwner => _currentUser?.isDryerOwner ?? false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    _auth.authStateChanges().listen((User? user) async {
      print('Auth state changed. User: ${user?.uid}');

      if (user != null) {
        await _loadUserFromFirestore(user.uid);
      } else {
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      print('Loading user data from Firestore for UID: $uid');

      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      log('Firestore document snapshot: ${docSnapshot.data()}');
      if (docSnapshot.exists && docSnapshot.data() != null) {
        _currentUser = UserModel.fromMap(
          docSnapshot.data()!,
          docSnapshot.id,
        );
        print('User loaded successfully: ${_currentUser?.name}');
      } else {
        print('User document does not exist in Firestore');
        _currentUser = null;
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading user from Firestore: $e');
      _currentUser = null;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        _currentUser = null;
        _isInitialized = true;
        return;
      }

      await _loadUserFromFirestore(user.uid);
      _errorMessage = null;
    } catch (e) {
      print('Error in loadCurrentUser: $e');
      _errorMessage = 'Failed to load user data';
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('Attempting sign in for: $email');

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final user = _auth.currentUser;

      if (user != null) {
        await _loadUserFromFirestore(user.uid);

        if (_currentUser != null) {
          print('Sign in successful');
          return true;
        } else {
          print('User document not found in Firestore');
          _errorMessage = 'User data not found. Please contact support.';
          return false;
        }
      }

      _errorMessage = 'Sign in failed';
      return false;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign in: ${e.code}');
      _errorMessage = _getErrorMessage(e);
      _currentUser = null;
      return false;
    } catch (e) {
      print('Unexpected error during sign in: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _currentUser = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('Attempting sign up for: $email');

      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final user = _auth.currentUser;

      if (user != null) {
        final userData = {
          'uid': user.uid,
          'email': email.trim(),
          'name': name.trim(),
          'phone': phone.trim(),
          'role': role,
          'isAdmin': role == 'admin',
          'isDryerOwner': role == 'dryer_owner',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(user.uid).set(userData);

        print('User document created in Firestore');

        await _loadUserFromFirestore(user.uid);

        print('Sign up successful');
        return true;
      }

      _errorMessage = 'Sign up failed';
      return false;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign up: ${e.code}');
      _errorMessage = _getErrorMessage(e);
      _currentUser = null;

      try {
        final user = _auth.currentUser;
        if (user != null) {
          await user.delete();
        }
      } catch (deleteError) {
        print('Error cleaning up user after failed signup: $deleteError');
      }

      return false;
    } catch (e) {
      print('Unexpected error during sign up: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _currentUser = null;

      try {
        final user = _auth.currentUser;
        if (user != null) {
          await user.delete();
        }
      } catch (deleteError) {
        print('Error cleaning up user after failed signup: $deleteError');
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Signing out...');
      await _auth.signOut();

      _currentUser = null;
      _errorMessage = null;
      print('Sign out successful');
    } catch (e) {
      print('Sign out error: $e');
      _errorMessage = 'Failed to sign out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('Sending password reset to: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());

      print('Password reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Password reset error: ${e.code}');
      _errorMessage = _getErrorMessage(e);
      return false;
    } catch (e) {
      print('Unexpected error during password reset: $e');
      _errorMessage = 'Failed to send reset email';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(FirebaseAuthException error) {
    print('FirebaseAuthException: ${error.code} - ${error.message}');

    switch (error.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return error.message ?? 'Authentication error occurred.';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> ensureUserDocument() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      return docSnapshot.exists;
    } catch (e) {
      print('Error checking user document: $e');
      return false;
    }
  }
}
