import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/emergency_case.dart';
import '../models/case_detail.dart';
import '../models/user.dart';

/// Service untuk API Petugas SafePoint
/// Berdasarkan dokumentasi API /petugas/*
class PetugasService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token'; // Use same key as AuthService
  static Timer? _pollingTimer;
  static Timer? _locationTimer;
  static StreamController<List<NewAssignmentCase>>? _newAssignmentsController;
  static StreamController<UnreadCount>? _unreadCountController;
  static StreamController<CheckUpdatesResponse>? _updatesController;

  static var caseUpdatesStream;

  // ============================================================================
  // STREAMS
  // ============================================================================

  /// Stream untuk new assignments
  static Stream<List<NewAssignmentCase>> get newAssignmentsStream {
    _newAssignmentsController ??=
        StreamController<List<NewAssignmentCase>>.broadcast();
    return _newAssignmentsController!.stream;
  }

  /// Stream untuk unread count (badge notification)
  static Stream<UnreadCount> get unreadCountStream {
    _unreadCountController ??= StreamController<UnreadCount>.broadcast();
    return _unreadCountController!.stream;
  }

  /// Stream untuk check updates
  static Stream<CheckUpdatesResponse> get updatesStream {
    _updatesController ??= StreamController<CheckUpdatesResponse>.broadcast();
    return _updatesController!.stream;
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Login petugas
  /// POST /petugas/login
  static Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Petugas login attempt: $email');
      final response = await http.post(
        Uri.parse(ApiConfig.petugasLogin),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Petugas login response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final loginResponse = LoginResponse.fromJson(responseData['data']);

        // Save token
        await _storage.write(key: _tokenKey, value: loginResponse.token);

        return ApiResponse.success(
          message: responseData['message'],
          data: loginResponse,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Login gagal',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Petugas login error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Logout petugas
  /// POST /petugas/logout
  static Future<ApiResponse<void>> logout() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        await http.post(
          Uri.parse(ApiConfig.petugasLogout),
          headers: ApiConfig.authHeaders(token),
        );
      }

      // Clear storage and stop services
      await _storage.delete(key: _tokenKey);
      stopPolling();
      stopLocationTracking();

      return ApiResponse.success(
        message: 'Logout berhasil',
        statusCode: 200,
      );
    } catch (e) {
      // Still clear local data even if API call fails
      await _storage.delete(key: _tokenKey);
      stopPolling();
      stopLocationTracking();

      return ApiResponse.success(
        message: 'Logout berhasil',
        statusCode: 200,
      );
    }
  }

  /// Get profile petugas
  /// GET /petugas/profile
  static Future<ApiResponse<User>> getProfile() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse(ApiConfig.petugasProfile),
        headers: ApiConfig.authHeaders(token),
      );

      print('Get profile response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final user = User.fromJson(responseData['data']);

        return ApiResponse.success(
          message: responseData['message'],
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal mengambil profil',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Get profile error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // ============================================================================
  // CASE MANAGEMENT
  // ============================================================================

  /// Get assigned cases
  /// GET /petugas/cases/assigned
  static Future<ApiResponse<List<EmergencyCase>>> getAssignedCases({
    String? status,
    int? perPage,
    int? page,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (perPage != null) queryParams['per_page'] = perPage.toString();
      if (page != null) queryParams['page'] = page.toString();

      final uri = Uri.parse(ApiConfig.assignedCases).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      print('Get assigned cases response: ${response.statusCode}');
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
      print('Get assigned cases error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Get case detail
  /// GET /petugas/cases/{case_id}
  static Future<ApiResponse<CaseDetail>> getCaseDetail(String caseId) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse(ApiConfig.petugasCase(caseId)),
        headers: ApiConfig.authHeaders(token),
      );

      print('Get case detail response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final caseDetail = CaseDetail.fromJson(responseData['data']);

        return ApiResponse.success(
          message: responseData['message'],
          data: caseDetail,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal mengambil detail kasus',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Get case detail error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Update case status
  /// POST /petugas/cases/{case_id}/status
  static Future<ApiResponse<Map<String, dynamic>>> updateCaseStatus({
    required String caseId,
    required String status,
    String? notes,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.post(
        Uri.parse(ApiConfig.caseStatus(caseId)),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'status': status,
          if (notes != null) 'notes': notes,
        }),
      );

      print('Update case status response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(
          message: responseData['message'],
          data: responseData['data'],
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal update status kasus',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Update case status error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Close case
  /// POST /petugas/cases/{case_id}/close
  static Future<ApiResponse<Map<String, dynamic>>> closeCase({
    required String caseId,
    required String resolutionNotes,
    List<String>? photos,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.post(
        Uri.parse(ApiConfig.closeCase(caseId)),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'resolution_notes': resolutionNotes,
          if (photos != null) 'photos': photos,
        }),
      );

      print('Close case response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(
          message: responseData['message'],
          data: responseData['data'],
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal menutup kasus',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Close case error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // ============================================================================
  // NOTIFICATIONS
  // ============================================================================

  /// Get new assignments
  /// GET /petugas/cases/new-assignments
  static Future<ApiResponse<List<NewAssignmentCase>>> getNewAssignments({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();

      final uri = Uri.parse(ApiConfig.newAssignments).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      print('Get new assignments response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> casesData = responseData['data'] ?? [];
        final List<NewAssignmentCase> cases = casesData
            .map((caseData) => NewAssignmentCase.fromJson(caseData))
            .toList();

        // Emit to stream
        _newAssignmentsController?.add(cases);

        return ApiResponse.success(
          message: responseData['message'],
          data: cases,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal mengambil kasus baru',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Get new assignments error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Get unread count
  /// GET /petugas/notifications/unread-count
  static Future<ApiResponse<UnreadCount>> getUnreadCount() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse(ApiConfig.unreadCount),
        headers: ApiConfig.authHeaders(token),
      );

      print('Get unread count response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final unreadCount = UnreadCount.fromJson(responseData['data']);

        // Emit to stream
        _unreadCountController?.add(unreadCount);

        return ApiResponse.success(
          message: responseData['message'],
          data: unreadCount,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message:
              responseData['message'] ?? 'Gagal mengambil jumlah notifikasi',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Get unread count error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Check updates (polling)
  /// GET /petugas/check-updates
  static Future<ApiResponse<CheckUpdatesResponse>> checkUpdates({
    String? lastCheck,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (lastCheck != null) queryParams['last_check'] = lastCheck;
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();

      final uri = Uri.parse(ApiConfig.checkUpdates).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      print('Check updates response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final updates = CheckUpdatesResponse.fromJson(responseData);

        // Emit to stream
        _updatesController?.add(updates);

        return ApiResponse.success(
          message: responseData['message'],
          data: updates,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal mengecek update',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Check updates error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // ============================================================================
  // LOCATION TRACKING
  // ============================================================================

  /// Update petugas location
  /// POST /petugas/location/update
  static Future<ApiResponse<Map<String, dynamic>>> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.post(
        Uri.parse(ApiConfig.updateLocation),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          if (accuracy != null) 'accuracy': accuracy,
        }),
      );

      print('Update location response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(
          message: responseData['message'],
          data: responseData['data'],
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal update lokasi',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Update location error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Get current location
  /// GET /petugas/location/current
  static Future<ApiResponse<CurrentLocation>> getCurrentLocation() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse(ApiConfig.currentLocation),
        headers: ApiConfig.authHeaders(token),
      );

      print('Get current location response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final location = CurrentLocation.fromJson(responseData['data']);

        return ApiResponse.success(
          message: responseData['message'],
          data: location,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal mengambil lokasi',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Get current location error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // ============================================================================
  // WHAT3WORDS INTEGRATION
  // ============================================================================

  /// Get What3Words from coordinates
  /// GET /petugas/location/what3words
  static Future<ApiResponse<What3WordsResponse>> getWhat3Words({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final uri = Uri.parse(ApiConfig.what3words).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      print('Get What3Words response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final what3words = What3WordsResponse.fromJson(responseData['data']);

        return ApiResponse.success(
          message: responseData['message'],
          data: what3words,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal mendapatkan What3Words',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Get What3Words error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Get coordinates from What3Words
  /// GET /petugas/location/coordinates
  static Future<ApiResponse<What3WordsResponse>> getCoordinatesFromWhat3Words({
    required String words,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        return ApiResponse.error(
          message: 'Token tidak ditemukan',
          statusCode: 401,
        );
      }

      final uri = Uri.parse(ApiConfig.coordinates).replace(
        queryParameters: {
          'words': words,
        },
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      print('Get coordinates response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final what3words = What3WordsResponse.fromJson(responseData['data']);

        return ApiResponse.success(
          message: responseData['message'],
          data: what3words,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          message: responseData['message'] ?? 'Gagal mendapatkan koordinat',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Get coordinates error: $e');
      return ApiResponse.error(
        message: 'Kesalahan jaringan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // ============================================================================
  // BACKGROUND SERVICES (POLLING & LOCATION TRACKING)
  // ============================================================================

  /// Start polling untuk real-time updates
  /// Poll every 30 seconds
  static void startPolling({double? latitude, double? longitude}) {
    print('Starting polling for updates...');
    stopPolling();

    _pollingTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      // Check updates
      await checkUpdates(
        latitude: latitude,
        longitude: longitude,
      );

      // Get unread count
      await getUnreadCount();
    });

    // Initial check
    checkUpdates(latitude: latitude, longitude: longitude);
    getUnreadCount();
  }

  /// Stop polling
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('Polling stopped');
  }

  /// Start location tracking
  /// Update location every 10-30 seconds
  static void startLocationTracking({
    required double latitude,
    required double longitude,
    double? accuracy,
    Duration interval = const Duration(seconds: 15),
  }) {
    print('Starting location tracking...');
    stopLocationTracking();

    _locationTimer = Timer.periodic(interval, (timer) async {
      await updateLocation(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
    });

    // Initial update
    updateLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }

  /// Stop location tracking
  static void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    print('Location tracking stopped');
  }

  /// Dispose all resources
  static void dispose() {
    stopPolling();
    stopLocationTracking();
    _newAssignmentsController?.close();
    _unreadCountController?.close();
    _updatesController?.close();
    _newAssignmentsController = null;
    _unreadCountController = null;
    _updatesController = null;
  }

  static getDashboardStats() {}
}
