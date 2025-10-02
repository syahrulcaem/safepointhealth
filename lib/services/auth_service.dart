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
    try {
      // First try regular citizen login endpoint
      print('Trying citizen login for: $email');
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Citizen login response status: ${response.statusCode}');
      print('Citizen login response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('Citizen login successful');
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
        print('Citizen login failed, trying petugas login...');
        // If regular login fails, try petugas login endpoint
        return await petugasLogin(email: email, password: password);
      }
    } catch (e) {
      print('Citizen login exception: $e');
      // If regular login fails with exception, try petugas login
      try {
        return await petugasLogin(email: email, password: password);
      } catch (e2) {
        print('Both login attempts failed: $e2');
        return ApiResponse.error(
          message: 'Kesalahan jaringan: ${e.toString()}',
          statusCode: 500,
        );
      }
    }
  }

  // Login petugas
  static Future<ApiResponse<LoginResponse>> petugasLogin({
    required String email,
    required String password,
  }) async {
    try {
      print('Trying petugas login with: $email');
      final response = await http.post(
        Uri.parse(ApiConfig.petugasLogin),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Petugas login response status: ${response.statusCode}');
      print('Petugas login response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('Petugas login successful, parsing data...');
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
        print('Petugas login failed: ${responseData['message']}');
        return ApiResponse.error(
          message: responseData['message'] ?? 'Login petugas gagal',
          errors: responseData['errors'],
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Petugas login exception: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
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

      final response = await http.get(
        Uri.parse(ApiConfig.me),
        headers: ApiConfig.authHeaders(token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final user = User.fromJson(responseData['data']);
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
      final userJson = await _storage.read(key: _userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      print('Error getting stored user: $e');
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
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
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
