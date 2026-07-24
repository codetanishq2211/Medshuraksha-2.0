import 'package:flutter/material.dart';
import 'package:medsuraksha_app/screens/splash_screen.dart';
import 'package:medsuraksha_app/theme/app_theme.dart';

void main() {
  runApp(const MedSurakshaApp());
}

class MedSurakshaApp extends StatelessWidget {
  const MedSurakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedSuraksha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}