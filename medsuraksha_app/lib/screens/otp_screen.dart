import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'profile_setup_screen.dart';
import 'main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const Color bg = Color(0xff0F1620);
  static const Color surfaceContainerLow = Color(0xff151C26);
  static const Color primaryContainer = Color(0xff69F0AE);
  static const Color onPrimaryContainer = Color(0xff006C45);
  static const Color onSurfaceVariant = Color(0xffBCCABF);

  final TextEditingController otpController = TextEditingController();
  bool isVerifying = false;
  String? error;

  Future<void> _verify() async {
    final code = otpController.text.trim();
    if (code.length != 6) {
      setState(() => error = "Enter the 6-digit code");
      return;
    }

    setState(() {
      isVerifying = true;
      error = null;
    });

    try {
      final result = await AuthService.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      final uid = result.user?.uid;
      if (uid == null) {
        throw Exception("Sign-in succeeded but no user ID was returned");
      }

      // Check whether this user already has a saved profile
      final profile = await ApiService.getProfile(uid);

      if (!mounted) return;

      if (profile != null && profile["has_profile"] == true) {
        // Existing user with a complete profile - go straight to the app
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        // New user, or signed in before but never finished setup
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              firebaseUid: uid,
              phoneNumber: widget.phoneNumber,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isVerifying = false;
        error = "Invalid code, try again";
      });
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sms, color: primaryContainer, size: 48),
              const SizedBox(height: 20),
              const Text(
                "Verify your number",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the 6-digit code sent to ${widget.phoneNumber}",
                style: const TextStyle(color: onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 28),

              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isVerifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryContainer,
                    foregroundColor: onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: onPrimaryContainer),
                        )
                      : const Text("Verify", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}