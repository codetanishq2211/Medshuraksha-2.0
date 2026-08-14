import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'main_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), _routeNext);
  }

  Future<void> _routeNext() async {
    final user = AuthService.currentUser;

    if (user == null) {
      // Not signed in at all - start the phone login flow
      _goTo(const LoginScreen());
      return;
    }

    // Signed in - check whether they've finished profile setup
    try {
      final profile = await ApiService.getProfile(user.uid);
      if (profile != null && profile["has_profile"] == true) {
        _goTo(const MainScreen());
      } else {
        _goTo(ProfileSetupScreen(
          firebaseUid: user.uid,
          phoneNumber: user.phoneNumber ?? "",
        ));
      }
    } catch (_) {
      // Profile fetch failed (e.g. backend briefly unreachable) - don't get
      // the user stuck on the splash screen, let them into the app and the
      // home screen's own profile fetch will retry.
      _goTo(const MainScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.greenAccent,
                size: 70,
              ),
            ).animate().scale(duration: 900.ms).fadeIn(),

            const SizedBox(height: 30),

            const Text(
              "MedSuraksha",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 10),

            const Text(
              "AI Powered Medicine Verification",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 70),

            const CircularProgressIndicator(
              color: Colors.greenAccent,
            ).animate().fadeIn(delay: 900.ms),
          ],
        ),
      ),
    );
  }
}