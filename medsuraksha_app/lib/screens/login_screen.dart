import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'guest_setup_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color bg = Color(0xff0F1620);
  static const Color surfaceContainerLow = Color(0xff151C26);
  static const Color primaryContainer = Color(0xff69F0AE);
  static const Color onPrimaryContainer = Color(0xff006C45);
  static const Color onSurfaceVariant = Color(0xffBCCABF);

  final TextEditingController phoneController = TextEditingController();
  bool isSending = false;
  String? error;

  Future<void> _sendOtp() async {
    final rawPhone = phoneController.text.trim();
    if (rawPhone.length < 10) {
      setState(() => error = "Enter a valid 10-digit phone number");
      return;
    }

    // Assumes Indian numbers - adjust the country code if needed
    final e164Phone = rawPhone.startsWith("+") ? rawPhone : "+91$rawPhone";

    setState(() {
      isSending = true;
      error = null;
    });

    await AuthService.sendOtp(
      phoneNumber: e164Phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => isSending = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: e164Phone,
            ),
          ),
        );
      },
      onVerificationFailed: (msg) {
        if (!mounted) return;
        setState(() {
          isSending = false;
          error = msg;
        });
      },
      onAutoVerified: (credential) {
        // Android auto-detected the SMS and signed in already.
        // The app's auth-state listener (wherever you check
        // AuthService.currentUser) should pick this up and navigate on.
        if (!mounted) return;
        setState(() => isSending = false);
      },
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
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
              const Icon(Icons.medication, color: primaryContainer, size: 56),
              const SizedBox(height: 24),
              const Text(
                "Welcome to MedShuraksha",
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your phone number to get started",
                style: TextStyle(color: onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "10-digit phone number",
                  hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.5)),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text("+91", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
                  onPressed: isSending ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryContainer,
                    foregroundColor: onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: onPrimaryContainer),
                        )
                      : const Text("Send OTP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GuestSetupScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Continue without sign in", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}