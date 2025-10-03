import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login user (try both citizen and officer endpoints)
  static Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    print('🔐 Attempting login for: $email');
    print('📡 Will try both citizen and petugas endpoints...');

    ApiResponse<LoginResponse>? citizenResult;
    ApiResponse<LoginResponse>? petugasResult;

    // Try citizen login first
    try {
      print('\n1️⃣ Trying CITIZEN login endpoint...');
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('   ✅ CITIZEN login successful!');
        final loginResponse = LoginResponse.fromJson(responseData['data']);

        // Save token and user data
        await _storage.write(key: _tokenKey, value: loginResponse.token);
        await _saveUserData(loginResponse.user);

        return ApiResponse.success(
          message: responseData['message'],
          data: loginResponse,
          statusCode: response.statusCode,
        );
      } else {
        print('   ❌ CITIZEN login failed: ${responseData['message']}');
        citizenResult = ApiResponse.error(
          message: responseData['message'] ?? 'Login warga gagal',
          errors: responseData['errors'],
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('   ⚠️ CITIZEN login exception: $e');
      citizenResult = ApiResponse.error(
        message: 'Kesalahan koneksi ke endpoint warga',
        statusCode: 500,
      );
    }

    // Try petugas login
    try {
      print('\n2️⃣ Trying PETUGAS login endpoint...');
      final response = await http.post(
        Uri.parse(ApiConfig.petugasLogin),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('   ✅ PETUGAS login successful!');
        final loginResponse = LoginResponse.fromJson(responseData['data']);

        // Save token and user data
        await _storage.write(key: _tokenKey, value: loginResponse.token);
        await _saveUserData(loginResponse.user);

        return ApiResponse.success(
          message: responseData['message'],
          data: loginResponse,
          statusCode: response.statusCode,
        );
      } else {
        print('   ❌ PETUGAS login failed: ${responseData['message']}');
        petugasResult = ApiResponse.error(
          message: responseData['message'] ?? 'Login petugas gagal',
          errors: responseData['errors'],
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('   ⚠️ PETUGAS login exception: $e');
      petugasResult = ApiResponse.error(
        message: 'Kesalahan koneksi ke endpoint petugas',
        statusCode: 500,
      );
    }

    // Both failed - return appropriate error message
    print('\n❌ Both login attempts failed');

    // Check if it's wrong credentials (401) or account not found (404)
    if (citizenResult.statusCode == 401 || petugasResult.statusCode == 401) {
      return ApiResponse.error(
        message: 'Email atau password salah',
        statusCode: 401,
      );
    } else if (citizenResult.statusCode == 404 ||
        petugasResult.statusCode == 404) {
      return ApiResponse.error(
        message: 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.',
        statusCode: 404,
      );
    } else {
      return ApiResponse.error(
        message: 'Login gagal. Periksa email dan password Anda.',
        statusCode: citizenResult.statusCode ?? petugasResult.statusCode ?? 500,
      );
    }
  }

  // Register user (hanya untuk warga)
  static Future<ApiResponse<LoginResponse>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    UserRole role = UserRole.WARGA,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone,
          'role': role.toString().split('.').last,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        final loginResponse = LoginResponse.fromJson(responseData['data']);

        // Save token and user data
        await _storage.write(key: _tokenKey, value: loginResponse.token);
        await _saveUserData(loginResponse.user);

        return ApiResponse.success(
          message: responseData['message'],
          data: loginResponse,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Pendaftaran gagal',
          errors: responseData['errors'],
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Logout user
  static Future<ApiResponse<void>> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        final response = await http.post(
          Uri.parse(ApiConfig.logout),
          headers: ApiConfig.authHeaders(token),
        );

        if (response.statusCode == 200) {
          await clearAuth();
          return ApiResponse.success(
            message: 'Logged out successfully',
            statusCode: response.statusCode,
          );
        }
      }

      // Clear auth data even if API call fails
      await clearAuth();
      return ApiResponse.success(
        message: 'Logged out successfully',
        statusCode: 200,
      );
    } catch (e) {
      // Clear auth data even if error occurs
      await clearAuth();
      return ApiResponse.success(
        message: 'Logged out successfully',
        statusCode: 200,
      );
    }
  }

  // Get current user
  static Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) {
        return ApiResponse.error(
          message: 'No authentication token found',
          statusCode: 401,
        );
      }

      // Add timestamp to avoid caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '${ApiConfig.me}?t=$timestamp';

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );

      print('=== Get Current User Response ===');
      print('URL: $url');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('=================================');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Check if response has nested user object
        var userData = responseData['data'];
        if (userData != null && userData['user'] != null) {
          print('✅ Response has nested user object');
          userData = userData['user'];
        } else {
          print('ℹ️ Response has direct user data');
        }

        final user = User.fromJson(userData);
        await _saveUserData(user);

        return ApiResponse.success(
          message: responseData['message'],
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Failed to get user data',
          errors: responseData['errors'],
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        message: 'Network error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get stored user data
  static Future<User?> getStoredUser() async {
    try {
      print('📖 Reading stored user data...');
      final userJson = await _storage.read(key: _userKey);
      if (userJson != null && userJson.isNotEmpty) {
        final user = User.fromJson(jsonDecode(userJson));
        print('✅ Stored user found: ${user.name} (${user.email})');
        return user;
      } else {
        print('⚠️ No stored user data found');
      }
    } catch (e) {
      print('❌ Error getting stored user: $e');
    }
    return null;
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear authentication data
  static Future<void> clearAuth() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // Save user data to FlutterSecureStorage
  static Future<void> _saveUserData(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: _userKey, value: userJson);
      print(
          '💾 User data saved to secure storage: ${user.name} (${user.email})');

      // Verify save was successful
      final savedUser = await getStoredUser();
      if (savedUser != null) {
        print('✅ Verified: User data persisted successfully');
      } else {
        print('⚠️ Warning: User data may not have been saved properly');
      }
    } catch (e) {
      print('❌ Error saving user data: $e');
      rethrow;
    }
  }

  // Refresh token if needed
  static Future<bool> refreshTokenIfNeeded() async {
    try {
      final response = await getCurrentUser();
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
