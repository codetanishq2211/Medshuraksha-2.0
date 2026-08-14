import 'package:flutter/material.dart';

import 'main_screen.dart';

class GuestSetupScreen extends StatefulWidget {
  const GuestSetupScreen({super.key});

  @override
  State<GuestSetupScreen> createState() => _GuestSetupScreenState();
}

class _GuestSetupScreenState extends State<GuestSetupScreen> {
  static const Color bg = Color(0xff0F1620);
  static const Color surfaceContainerLow = Color(0xff151C26);
  static const Color primaryContainer = Color(0xff69F0AE);
  static const Color onPrimaryContainer = Color(0xff006C45);
  static const Color onSurfaceVariant = Color(0xffBCCABF);

  final TextEditingController nameController = TextEditingController();
  bool isSaving = false;
  String? error;

  Future<void> _continueAsGuest() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      setState(() => error = "Enter your name to continue");
      return;
    }

    setState(() {
      isSaving = true;
      error = null;
    });

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainScreen(userName: name)),
      (route) => false,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
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
              const Icon(Icons.person_outline, color: primaryContainer, size: 56),
              const SizedBox(height: 24),
              const Text(
                "Continue without sign in",
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your name and continue using the app.",
                style: TextStyle(color: onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Your name",
                  hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.person, color: onSurfaceVariant),
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
                  onPressed: isSaving ? null : _continueAsGuest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryContainer,
                    foregroundColor: onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: onPrimaryContainer),
                        )
                      : const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
