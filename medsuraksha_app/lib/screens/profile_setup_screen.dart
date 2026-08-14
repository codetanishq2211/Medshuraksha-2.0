import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String firebaseUid;
  final String phoneNumber;

  const ProfileSetupScreen({
    super.key,
    required this.firebaseUid,
    required this.phoneNumber,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const Color bg = Color(0xff0F1620);
  static const Color surfaceContainerLow = Color(0xff151C26);
  static const Color primaryContainer = Color(0xff69F0AE);
  static const Color onPrimaryContainer = Color(0xff006C45);
  static const Color onSurfaceVariant = Color(0xffBCCABF);

  final TextEditingController nameController = TextEditingController();
  DateTime? dateOfBirth;
  bool isSaving = false;
  String? error;

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryContainer,
              onPrimary: onPrimaryContainer,
              surface: surfaceContainerLow,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => dateOfBirth = picked);
    }
  }

  Future<void> _saveProfile() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      setState(() => error = "Enter your name");
      return;
    }
    if (dateOfBirth == null) {
      setState(() => error = "Select your date of birth");
      return;
    }

    setState(() {
      isSaving = true;
      error = null;
    });

    try {
      final dobString =
          "${dateOfBirth!.year.toString().padLeft(4, '0')}-"
          "${dateOfBirth!.month.toString().padLeft(2, '0')}-"
          "${dateOfBirth!.day.toString().padLeft(2, '0')}";

      await ApiService.saveProfile(
        firebaseUid: widget.firebaseUid,
        phoneNumber: widget.phoneNumber,
        name: name,
        dateOfBirth: dobString,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        error = "Couldn't save profile: $e";
      });
    }
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
              const Icon(Icons.person_add, color: primaryContainer, size: 48),
              const SizedBox(height: 20),
              const Text(
                "Create your profile",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Just a couple more details to get started",
                style: TextStyle(color: onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Full name",
                  hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.person_outline, color: onSurfaceVariant),
                  filled: true,
                  fillColor: surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDateOfBirth,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        dateOfBirth == null
                            ? "Date of birth"
                            : "${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}",
                        style: TextStyle(
                          color: dateOfBirth == null
                              ? onSurfaceVariant.withOpacity(0.5)
                              : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
                  onPressed: isSaving ? null : _saveProfile,
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