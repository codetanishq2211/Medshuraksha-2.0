import 'package:flutter/material.dart';

class MedicineDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailsScreen({
    super.key,
    required this.medicine,
  });

  @override
  Widget build(BuildContext context) {
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