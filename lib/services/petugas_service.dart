import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/emergency_case.dart';

class PetugasService {
  static const _storage = FlutterSecureStorage();
  static Timer? _pollingTimer;
  static StreamController<List<EmergencyCase>>? _caseStreamController;

  // Get stream untuk real-time case updates
  static Stream<List<EmergencyCase>> get caseUpdatesStream {
    _caseStreamController ??= StreamController<List<EmergencyCase>>.broadcast();
    return _caseStreamController!.stream;
  }

  // Start polling untuk check updates
  static void startPolling() {
    print('Starting petugas polling...');
    stopPolling(); // Stop existing timer first

    _pollingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      checkForUpdates();
    });

    // Initial check
    checkForUpdates();
  }

  // Stop polling
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Check for case updates
  static Future<void> checkForUpdates() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/petugas/check-updates'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      print('Check updates response: ${response.statusCode}');
      print('Check updates body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> casesData = responseData['data']['cases'] ?? [];
          final List<EmergencyCase> cases = casesData
              .map((caseData) => EmergencyCase.fromJson(caseData))
              .toList();

          // Emit ke stream
          _caseStreamController?.add(cases);

          print('Updated cases count: ${cases.length}');
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  // Get assigned cases
  static Future<ApiResponse<List<EmergencyCase>>> getAssignedCases() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/petugas/cases'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      print('Get assigned cases response: ${response.statusCode}');
      print('Get assigned cases body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> casesData = responseData['data'] ?? [];
        final List<EmergencyCase> cases = casesData
            .map((caseData) => EmergencyCase.fromJson(caseData))
            .toList();

        return ApiResponse.success(
          message: responseData['message'],
          data: cases,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal mengambil data kasus',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error getting assigned cases: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Update case status
  static Future<ApiResponse<EmergencyCase>> updateCaseStatus({
    required String caseId,
    required String status,
    String? notes,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/petugas/cases/$caseId/status'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'notes': notes,
        }),
      );

      print('Update case status response: ${response.statusCode}');
      print('Update case status body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final EmergencyCase updatedCase =
            EmergencyCase.fromJson(responseData['data']);

        return ApiResponse.success(
          message: responseData['message'],
          data: updatedCase,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal update status kasus',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error updating case status: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Update duty status
  static Future<ApiResponse<bool>> updateDutyStatus({
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/petugas/duty-status'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      print('Update duty status response: ${response.statusCode}');
      print('Update duty status body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(
          message: responseData['message'],
          data: true,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal update status tugas',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error updating duty status: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get dashboard statistics
  static Future<ApiResponse<Map<String, dynamic>>> getDashboardStats() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/petugas/dashboard'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      print('Get dashboard stats response: ${response.statusCode}');
      print('Get dashboard stats body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(
          message: responseData['message'],
          data: responseData['data'],
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message:
              responseData['message'] ?? 'Gagal mengambil statistik dashboard',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Dispose resources
  static void dispose() {
    stopPolling();
    _caseStreamController?.close();
    _caseStreamController = null;
  }
}
