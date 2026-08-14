import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'medicine_details_screen.dart';
import 'medicine_ai_result_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;

  const HomeScreen({super.key, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _RecentActivity {
  final String name;
  final bool approved;
  final dynamic medicine; // full map, for navigating back into details
  final String? aiAnswer; // set if this came from the AI fallback path

  _RecentActivity({
    required this.name,
    required this.approved,
    this.medicine,
    this.aiAnswer,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------------------------- design tokens (Clinical Precision Mobile)
  static const Color bg = Color(0xff0F1620);
  static const Color surfaceContainerLow = Color(0xff151C26);
  static const Color surfaceContainer = Color(0xff19202A);
  static const Color surfaceContainerHigh = Color(0xff232A35);
  static const Color surfaceContainerHighest = Color(0xff2E3540);
  static const Color primaryContainer = Color(0xff69F0AE);
  static const Color onPrimaryContainer = Color(0xff006C45);
  static const Color secondary = Color(0xffFFB866);
  static const Color onSurfaceVariant = Color(0xffBCCABF);
  static const Color outline = Color(0xff86948A);
  static const Color outlineVariant = Color(0xff3D4A41);
  static const Color onSurface = Color(0xffDCE3F1);

  final TextEditingController searchController = TextEditingController();

  List<dynamic> medicines = [];
  bool isLoading = false;

  // Session-only activity tracking (resets on app restart - no backend
  // history endpoint wired up yet)
  final List<_RecentActivity> recentActivity = [];
  int get totalVerified => recentActivity.where((a) => a.approved).length;
  int get weeklyScans => recentActivity.length;

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

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showingSearchResults = searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _searchBar(),
                        const SizedBox(height: 24),

                        if (showingSearchResults) ...[
                          _searchResultsSection(),
                        ] else ...[
                          _greeting(),
                          const SizedBox(height: 24),
                          _statsBentoGrid(),
                          const SizedBox(height: 24),
                          _recentScansHeader(),
                          const SizedBox(height: 16),
                          if (recentActivity.isEmpty)
                            _emptyState()
                          else
                            _recentActivityList(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------- scan FAB
          Positioned(
            right: 16,
            bottom: 96,
            child: GestureDetector(
              onTap: _openScanner,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primaryContainer.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.photo_camera, color: onPrimaryContainer, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- top bar
  Widget _topBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: bg,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "MedShuraksha",
            style: TextStyle(
              color: primaryContainer,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(Icons.notifications_none, color: onSurfaceVariant),
        ],
      ),
    );
  }

  // ---------------------------- search bar
  Widget _searchBar() {
    return TextField(
      controller: searchController,
      onChanged: searchMedicine,
      style: const TextStyle(color: onSurface),
      decoration: InputDecoration(
        hintText: "Search medicines or scans...",
        hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.5)),
        prefixIcon: const Icon(Icons.search, color: onSurfaceVariant),
        filled: true,
        fillColor: surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryContainer, width: 1),
        ),
      ),
    );
  }

  String get _displayName {
    final value = widget.userName;
    return (value != null && value.trim().isNotEmpty) ? value.trim() : "User";
  }

  // ---------------------------- greeting
  Widget _greeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, $_displayName",
          style: const TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          "Verify your medicine authenticity instantly.",
          style: TextStyle(color: onSurfaceVariant, fontSize: 14),
        ),
      ],
    );
  }

  // ---------------------------- stats bento grid
  Widget _statsBentoGrid() {
    return Row(
      children: [
        Expanded(
          child: _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user, color: primaryContainer),
                const SizedBox(height: 8),
                const Text(
                  "TOTAL VERIFIED",
                  style: TextStyle(
                    color: onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$totalVerified",
                  style: const TextStyle(
                    color: primaryContainer,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.qr_code_scanner, color: secondary),
                const SizedBox(height: 8),
                const Text(
                  "WEEKLY SCANS",
                  style: TextStyle(
                    color: onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$weeklyScans",
                  style: const TextStyle(
                    color: secondary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  // ---------------------------- recent scans header
  Widget _recentScansHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Recent Scans",
          style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        if (recentActivity.isNotEmpty)
          TextButton(
            onPressed: () {
              // TODO: wire to your History screen if you have one, e.g.:
              // Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
            style: TextButton.styleFrom(foregroundColor: primaryContainer),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("View All", style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------- empty state
  Widget _emptyState() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 200,
              decoration: BoxDecoration(
                color: surfaceContainer.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: outlineVariant, width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medication_outlined, color: outline, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: outline.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 90,
                    height: 6,
                    decoration: BoxDecoration(
                      color: surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_scanner, color: secondary, size: 20),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryContainer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, color: primaryContainer, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "No recent scans yet",
          style: TextStyle(color: onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Scan a medicine packet to verify its details and check for safety alerts.",
            textAlign: TextAlign.center,
            style: TextStyle(color: outline, fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _openScanner,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryContainer,
            foregroundColor: onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
          icon: const Icon(Icons.add),
          label: const Text("Start First Scan", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ---------------------------- recent activity list (once non-empty)
  Widget _recentActivityList() {
    return Column(
      children: recentActivity.map((activity) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (activity.medicine != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicineDetailsScreen(medicine: activity.medicine),
                  ),
                );
              } else if (activity.aiAnswer != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicineAiResultScreen(
                      guessedName: activity.name,
                      aiAnswer: activity.aiAnswer!,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                    activity.approved ? Icons.verified : Icons.warning_amber_rounded,
                    color: activity.approved ? primaryContainer : secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity.name,
                      style: const TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: outline),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------- search results (when typing)
  Widget _searchResultsSection() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: primaryContainer)),
      );
    }
    if (medicines.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text("No matches found.", style: TextStyle(color: onSurfaceVariant)),
      );
    }
    return Column(
      children: medicines.map((medicine) {
        final bool approved = medicine["approved"] == true;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                recentActivity.insert(
                  0,
                  _RecentActivity(
                    name: medicine["name"]?.toString() ?? "Unknown",
                    approved: approved,
                    medicine: medicine,
                  ),
                );
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MedicineDetailsScreen(medicine: medicine)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                    approved ? Icons.verified : Icons.warning_amber_rounded,
                    color: approved ? primaryContainer : secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine["name"]?.toString() ?? "Unknown",
                          style: const TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          medicine["manufacturer"]?.toString() ?? "",
                          style: const TextStyle(color: onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: outline),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}