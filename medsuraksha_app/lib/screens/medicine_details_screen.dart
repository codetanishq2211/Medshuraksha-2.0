import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailsScreen({
    super.key,
    required this.medicine,
  });

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  static const Color bgColor = Color(0xff0F1620);
  static const Color cardColor = Color(0xff182235);
  static const Color accentGreen = Color(0xff69F0AE);
  static const Color accentAmber = Color(0xffFFB866);
  static const Color mutedText = Color(0xff8A97A8);

  bool isLoadingAi = false;
  String? aiAnswer;
  String? aiError;

  Future<void> _fetchAiInfo(String name) async {
    setState(() {
      isLoadingAi = true;
      aiError = null;
    });

    try {
      final answer = await ApiService.askAI(
        "Tell me about the medicine '$name': what it's used for, common side "
        "effects, and who should avoid it.",
      );

      if (!mounted) return;
      setState(() {
        aiAnswer = answer;
        isLoadingAi = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        aiError = "Couldn't reach AI: $e";
        isLoadingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicine = widget.medicine;
    final String name = medicine["name"]?.toString() ?? "Unknown";
    final bool approved = medicine["approved"] == true;
    final String? manufacturer = medicine["manufacturer"]?.toString();
    final String? sideEffects = medicine["side_effects"]?.toString();
    final String? avoidIn = medicine["avoid_in"]?.toString();
    final String? additionalInfo = medicine["additional_info"]?.toString();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(name, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: accentGreen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------------------------- verification banner
            _verificationBanner(approved),

            const SizedBox(height: 20),

            // ---------------------------- identity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Icon(
                  approved ? Icons.check_circle : Icons.error_outline,
                  color: approved ? accentGreen : accentAmber,
                  size: 30,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ---------------------------- manufacturer (asymmetric full-width card)
            _asymmetricCard(
              icon: Icons.factory,
              label: "Manufacturer",
              child: Text(
                (manufacturer == null || manufacturer.trim().isEmpty)
                    ? "Not available"
                    : manufacturer,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ---------------------------- side effects / avoid in (bento pair)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _bentoCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: accentAmber,
                    label: "Side Effects",
                    child: Text(
                      (sideEffects == null || sideEffects.trim().isEmpty)
                          ? "None reported"
                          : sideEffects,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _bentoCard(
                    icon: Icons.block,
                    iconColor: Colors.redAccent,
                    label: "Avoid In",
                    child: Text(
                      (avoidIn == null || avoidIn.trim().isEmpty) ? "No" : avoidIn,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------------------- additional info (full-width)
            _bentoCard(
              icon: Icons.verified_user,
              iconColor: accentGreen,
              label: "Additional Information",
              child: Text(
                (additionalInfo == null || additionalInfo.trim().isEmpty)
                    ? "Not available"
                    : additionalInfo,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),

            const SizedBox(height: 16),

            // ---------------------------- AI assistant callout (dashed border)
            _aiAssistantCard(name),
          ],
        ),
      ),
    );
  }

  Widget _verificationBanner(bool approved) {
    final Color color = approved ? accentGreen : accentAmber;
    final String label = approved ? "Source: Verified Database" : "Source: Not Verified";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _asymmetricCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: accentGreen, width: 3),
          top: BorderSide(color: Colors.white10),
          right: BorderSide(color: Colors.white10),
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _bentoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _aiAssistantCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentAmber.withOpacity(0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentAmber.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: accentAmber, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "ASSISTANT INSIGHT",
                  style: TextStyle(
                    color: accentAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (aiAnswer == null && aiError == null)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Ask the AI assistant for extra context on this medicine.",
                    style: TextStyle(color: mutedText, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: isLoadingAi ? null : () => _fetchAiInfo(name),
                  style: TextButton.styleFrom(foregroundColor: accentAmber),
                  child: isLoadingAi
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentAmber,
                          ),
                        )
                      : const Text("Ask AI", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

          if (aiError != null) ...[
            Text(
              aiError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _fetchAiInfo(name),
              style: TextButton.styleFrom(foregroundColor: accentAmber),
              child: const Text("Try again"),
            ),
          ],

          if (aiAnswer != null)
            Text(
              aiAnswer!,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
        ],
      ),
    );
  }
}