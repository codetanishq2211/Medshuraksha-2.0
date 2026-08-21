import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_screen.dart';
import 'name_entry_screen.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');

    if (!mounted) return;

    if (savedName == null || savedName.trim().isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NameEntryScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
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