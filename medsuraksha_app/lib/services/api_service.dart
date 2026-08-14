import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Deployed backend on Render - works from anywhere, no laptop needed
  static const String baseUrl = "https://medshuraksha-2-0.onrender.com";

  // ===============================
  // Search Medicines
  // ===============================
  static Future<List<dynamic>> searchMedicine(String query) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/search?q=$query"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception(
          "Search failed (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Error searching medicine: $e");
    }
  }

  // ===============================
  // AI Chat
  // ===============================
  static Future<String> askAI(String question) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/ai/chat"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "question": question,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["answer"] ?? "";
      } else {
        throw Exception(
          "AI request failed (${response.statusCode})",
        );
      }
    } catch (e) {
      throw Exception("AI Error: $e");
    }
  }

  // ===============================
  // Upload Image for OCR
  // ===============================
  static Future<Map<String, dynamic>> uploadMedicineImage(
      String imagePath) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/scan/image"),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          imagePath,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "OCR failed (${response.statusCode})",
        );
      }
    } catch (e) {
      throw Exception("Upload Error: $e");
    }
  }

  // ===============================
  // Profile
  // ===============================

  /// Returns the profile map, or null if this user hasn't set one up yet
  /// (backend returns 404 in that case).
  static Future<Map<String, dynamic>?> getProfile(String firebaseUid) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/profile/$firebaseUid"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          "Profile fetch failed (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching profile: $e");
    }
  }

  /// Creates or updates the profile for [firebaseUid].
  /// [dateOfBirth] must be in "YYYY-MM-DD" format.
  static Future<Map<String, dynamic>> saveProfile({
    required String firebaseUid,
    String? phoneNumber,
    String? name,
    String? dateOfBirth,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/profile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firebase_uid": firebaseUid,
          "phone_number": phoneNumber,
          "name": name,
          "date_of_birth": dateOfBirth,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          "Profile save failed (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Error saving profile: $e");
    }
  }

  // ===============================
  // Backend Health Check
  // ===============================
  static Future<bool> isBackendOnline() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/"),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}