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

    return Scaffold(
      backgroundColor: const Color(0xff0F1620),

      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xff182235),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Icon(
              Icons.medication,
              size: 90,
              color: Colors.greenAccent,
            ),

            const SizedBox(height: 20),

            Text(
              name,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            infoCard("Manufacturer", medicine["manufacturer"]?.toString()),
            infoCard(
              "Approval Status",
              approved ? "Approved ✅" : "Not Approved ❌",
            ),
            infoCard("Side Effects", medicine["side_effects"]?.toString()),
            infoCard("Avoid In", medicine["avoid_in"]?.toString()),
            infoCard(
              "Additional Information",
              medicine["additional_info"]?.toString(),
            ),

            const SizedBox(height: 10),

            // ---------------------------- AI info section
            if (aiAnswer == null && aiError == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoadingAi ? null : () => _fetchAiInfo(name),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isLoadingAi
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        )
                      : const Icon(Icons.smart_toy, size: 18),
                  label: Text(isLoadingAi ? "Asking AI..." : "Ask AI for more info"),
                ),
              ),

            if (aiError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  aiError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _fetchAiInfo(name),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                  child: const Text("Try again"),
                ),
              ),
            ],

            if (aiAnswer != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.smart_toy, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "AI-generated, not verified",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff182235),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  aiAnswer!,
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget infoCard(String title, String? value) {
    return Card(
      color: const Color(0xff182235),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              title,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              (value == null || value.trim().isEmpty) ? "Not available" : value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}