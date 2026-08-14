import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'medicine_details_screen.dart';
import 'medicine_ai_result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const Color bg = Color(0xff0F1620);
  static const Color surfaceContainer = Color(0xff19202A);
  static const Color surfaceContainerLow = Color(0xff151C26);
  static const Color surfaceContainerHigh = Color(0xff232A35);
  static const Color primaryContainer = Color(0xff69F0AE);
  static const Color onPrimaryContainer = Color(0xff006C45);
  static const Color onSurface = Color(0xffDCE3F1);
  static const Color onSurfaceVariant = Color(0xffBCCABF);

  bool isUploading = false;
  String? status;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    setState(() {
      isUploading = true;
      status = "Uploading image...";
    });

    try {
      final result = await ApiService.uploadMedicineImage(file.path);
      if (!mounted) return;

      setState(() {
        isUploading = false;
        status = null;
      });

      final resultSource = result["source"];
      if (resultSource == "database") {
        final matches = (result["matches"] as List<dynamic>?) ?? [];
        if (matches.isNotEmpty) {
          final match = matches.first;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MedicineDetailsScreen(medicine: match)),
          );
          return;
        }
      }

      if (resultSource == "ai") {
        final guessedName = result["guessed_name"]?.toString() ?? "Unknown";
        final aiAnswer = result["ai_answer"]?.toString() ?? "No response from AI.";
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineAiResultScreen(guessedName: guessedName, aiAnswer: aiAnswer),
          ),
        );
        return;
      }

      _showSnack("Could not identify the medicine. Try a clearer image.");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isUploading = false;
        status = null;
      });
      _showSnack("Scan failed: $e");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: isUploading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: surfaceContainerLow,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text("Scan Medicine"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isUploading ? null : () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 230,
              decoration: BoxDecoration(
                color: surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_search, color: primaryContainer, size: 54),
                    const SizedBox(height: 16),
                    const Text(
                      "Upload a medicine image",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Use camera or gallery to scan the label",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onSurfaceVariant.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              icon: Icons.camera_alt,
              label: "Open Camera",
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.photo_library,
              label: "Choose from Gallery",
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 24),
            if (status != null)
              Text(
                status!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            const Spacer(),
            Text(
              "Tip: capture the label clearly for better recognition.",
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurfaceVariant.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
