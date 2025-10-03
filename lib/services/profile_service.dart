import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ProfileService {
  // Get user profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: ApiConfig.authHeaders(token),
      );

      print('=== Get Profile Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('===========================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // API returns: { success, data: { user: {...} } }
          // We need to return the user object
          if (data['data'] != null && data['data']['user'] != null) {
            print('✅ Returning user profile with citizen_profile');
            return data['data']['user'];
          }
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Flatten citizen_profile data to root level
      // Some APIs expect: { name, phone, nik, whatsapp_keluarga, ... }
      // Instead of: { name, phone, citizen_profile: { nik, ... } }
      Map<String, dynamic> flattenedData = {};

      // Add root level fields
      if (profileData.containsKey('name'))
        flattenedData['name'] = profileData['name'];
      if (profileData.containsKey('phone'))
        flattenedData['phone'] = profileData['phone'];

      // Flatten citizen_profile fields to root level
      if (profileData.containsKey('citizen_profile') &&
          profileData['citizen_profile'] is Map<String, dynamic>) {
        final citizenProfile =
            profileData['citizen_profile'] as Map<String, dynamic>;

        // Add each citizen_profile field to root level
        citizenProfile.forEach((key, value) {
          if (value != null && value != '') {
            flattenedData[key] = value;
          }
        });

        print('📋 Flattened citizen_profile fields to root level');
      }

      // Remove null/empty values
      flattenedData.removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty));

      print('=== Update Profile Request ===');
      print('URL: ${ApiConfig.baseUrl}/profile');
      print('Original Data: ${jsonEncode(profileData)}');
      print('Flattened Data: ${jsonEncode(flattenedData)}');
      print('==============================');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(flattenedData), // Use flattened data
      );

      print('=== Update Profile Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('===============================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Upload KTP image
  Future<String?> uploadKtpImage(XFile imageFile) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/profile/ktp'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'ktp_image',
          imageFile.path,
        ),
      );

      print('=== Upload KTP Request ===');
      print('URL: ${ApiConfig.baseUrl}/profile/ktp');
      print('File: ${imageFile.path}');
      print('=========================');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== Upload KTP Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('===========================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['ktp_image_url'];
        }
      }
      return null;
    } catch (e) {
      print('Error uploading KTP: $e');
      rethrow;
    }
  }
}
