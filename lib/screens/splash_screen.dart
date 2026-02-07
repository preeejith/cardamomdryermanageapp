import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for Firebase to initialize
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Get auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Wait for auth state to be checked
      int attempts = 0;
      while (!authProvider.isInitialized && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 300));
        attempts++;
      }
      
      if (!mounted) return;
      
      // Navigate based on auth state
      _navigateToNextScreen(authProvider);
      
    } catch (e) {
      print('Splash screen error: $e');
      
      if (mounted) {
        // On error, go to login
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _navigateToNextScreen(AuthProvider authProvider) {
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      print('User is authenticated: ${authProvider.currentUser?.email}');
      
      // Navigate based on role
      if (authProvider.isAdmin) {
        print('Navigating to admin dashboard');
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (authProvider.isDryerOwner) {
        print('Navigating to owner dashboard');
        Navigator.pushReplacementNamed(context, '/owner-dashboard');
      } else {
        print('Unknown role, going to login');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      print('User not authenticated, going to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.agriculture,
                size: 70,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            
            // App Name
            const Text(
              'Cardamom Dryer',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Management System',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 60),
            
            // Loading Indicator
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            
            // Loading Text
            Text(
              'Initializing...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 100),
            
            // Version
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}