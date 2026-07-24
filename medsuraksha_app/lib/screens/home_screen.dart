import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'medicine_details_screen.dart';
import 'medicine_ai_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();

  List<dynamic> medicines = [];
  bool isLoading = false;
  bool isScanning = false;

  Future<void> searchMedicine(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        medicines = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.searchMedicine(query);

      setState(() {
        medicines = result;
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _scanMedicine() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xff182235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.greenAccent),
                title: const Text("Take a photo", style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
                title: const Text("Choose from gallery", style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      isScanning = true;
    });

    try {
      final result = await ApiService.uploadMedicineImage(picked.path);

      if (!mounted) return;
      setState(() {
        isScanning = false;
      });

      final source = result["source"];

      if (source == "database") {
        final matches = (result["matches"] as List<dynamic>?) ?? [];
        if (matches.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicineDetailsScreen(medicine: matches.first),
            ),
          );
        } else {
          _showSnack("No match found in database.");
        }
      } else if (source == "ai") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineAiResultScreen(
              guessedName: result["guessed_name"] ?? "Unknown",
              aiAnswer: result["ai_answer"] ?? "No response from AI.",
            ),
          ),
        );
      } else {
        _showSnack("Couldn't read the label clearly. Try a clearer photo.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isScanning = false;
      });
      _showSnack("Scan failed: $e");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showingResults = searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xff0F1620),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        onPressed: isScanning ? null : _scanMedicine,
        icon: isScanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.qr_code_scanner),
        label: Text(
          isScanning ? "Scanning..." : "Scan",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: searchController,
                onChanged: searchMedicine,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search Medicines...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ---------------------------- search results (only while typing)
              if (showingResults) ...[
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.greenAccent),
                    ),
                  )
                else if (medicines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No matches found.",
                      style: TextStyle(color: Colors.white60),
                    ),
                  )
                else
                  Column(
                    children: medicines.map((medicine) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _medicineTile(medicine),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 10),
              ] else ...[
                // ---------------------------- default home content
                Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xff00D084),
                        Color(0xff00B56A),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 55,
                          color: Colors.white,
                        ),

                        const Spacer(),

                        const Text(
                          "Scan Medicine",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "AI Powered Medicine Scanner",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: _card(
                        Icons.document_scanner,
                        "OCR Scan",
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: _card(
                        Icons.smart_toy,
                        "AI Assistant",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  "Recent Scans",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                _medicineTile(const {
                  "name": "Dolo 650",
                  "manufacturer": "Micro Labs",
                  "approved": true,
                }),

                const SizedBox(height: 15),

                _medicineTile(const {
                  "name": "Crocin",
                  "manufacturer": "GSK",
                  "approved": true,
                }),

                const SizedBox(height: 15),

                _medicineTile(const {
                  "name": "Unknown Drug",
                  "manufacturer": "N/A",
                  "approved": false,
                }),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(IconData icon, String title) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xff182235),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.greenAccent,
            size: 35,
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicineTile(dynamic medicine) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineDetailsScreen(
              medicine: medicine,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff182235),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: (medicine["approved"] == true
                      ? Colors.green
                      : Colors.orange)
                  .withOpacity(0.15),
              child: Icon(
                medicine["approved"] == true
                    ? Icons.verified
                    : Icons.warning,
                color: medicine["approved"] == true
                    ? Colors.green
                    : Colors.orange,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine["name"] ?? "Unknown",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    medicine["manufacturer"] ?? "",
                    style: const TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}