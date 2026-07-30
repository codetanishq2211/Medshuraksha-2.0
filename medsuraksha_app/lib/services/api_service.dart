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

      print("STATUS = ${response.statusCode}");
      print("BODY = ${response.body}");

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