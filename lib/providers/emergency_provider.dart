import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:image_picker/image_picker.dart';
import '../models/emergency_case_new.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/emergency_cooldown_service.dart';

class EmergencyProvider with ChangeNotifier {
  List<EmergencyCase> _cases = [];
  List<EmergencyCase> _myCases = [];
  EmergencyCase? _activeCase;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isReporting = false;
  DateTime? _lastEmergencyTime;

  // Getters
  List<EmergencyCase> get cases => _cases;
  List<EmergencyCase> get myCases => _myCases;
  EmergencyCase? get activeCase => _activeCase;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isReporting => _isReporting;
  DateTime? get lastEmergencyTime => _lastEmergencyTime;

  // Check if user can report emergency (30 minutes cooldown)
  bool canReportEmergency() {
    if (_lastEmergencyTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastEmergencyTime!);
    return difference.inMinutes >= 30;
  }

  // Get remaining cooldown time in minutes
  int getRemainingCooldownMinutes() {
    if (_lastEmergencyTime == null) return 0;
    final now = DateTime.now();
    final difference = now.difference(_lastEmergencyTime!);
    final remaining = 30 - difference.inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  // Report emergency
  Future<bool> reportEmergency({
    required String phone,
    required double latitude,
    required double longitude,
    required EmergencyCategory category,
    required String description,
    double? accuracy,
    String? locatorText,
    List<XFile>? photos,
    String? audioRecord,
  }) async {
    _setReporting(true);
    _clearError();

    try {
      // Check cooldown for authenticated users
      final canReport = await EmergencyCooldownService.canReportEmergency();
      if (!canReport) {
        final remainingMinutes =
            await EmergencyCooldownService.getRemainingCooldownMinutes();
        _setError(
            'Anda baru saja mengirimkan laporan darurat. Harap tunggu $remainingMinutes menit lagi sebelum mengirim laporan berikutnya.');
        _setReporting(false);
        return false;
      }

      final token = await AuthService.getToken();
      if (token == null) {
        _setError('Authentication required');
        _setReporting(false);
        return false;
      }

      // Prepare request data sesuai format API
      Map<String, dynamic> requestData = {
        'latitude': latitude, // Gunakan 'latitude' bukan 'lat'
        'longitude': longitude, // Gunakan 'longitude' bukan 'lon'
        'description': description,
        'category': category.toString().split('.').last,
      };

      // Optional fields
      if (phone.isNotEmpty) {
        requestData['phone'] = phone;
      }
      if (accuracy != null) {
        requestData['accuracy'] = accuracy;
      }
      if (locatorText != null && locatorText.isNotEmpty) {
        requestData['locator_text'] = locatorText;
      }

      // Handle photo uploads if any
      if (photos != null && photos.isNotEmpty) {
        // For now, just add photo paths - in real app, you'd upload to server
        requestData['photos'] = photos.map((photo) => photo.path).toList();
      }

      if (audioRecord != null) {
        requestData['audio_record'] = audioRecord;
      }

      // Debug: Print request data
      print('=== Emergency Report Request ===');
      print('URL: ${ApiConfig.emergency}');
      print('Headers: ${ApiConfig.authHeaders(token)}');
      print('Body: ${jsonEncode(requestData)}');
      print('===============================');

      final response = await http
          .post(
        Uri.parse(ApiConfig.emergency),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(requestData),
      )
          .timeout(
        const Duration(seconds: 15), // Reduced timeout 15 detik
        onTimeout: () {
          throw Exception(
              'Request timeout - server tidak merespon dalam 15 detik');
        },
      );

      // Debug: Print response
      print('=== Emergency Report Response ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('================================');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        // Set last emergency time for cooldown (persistent)
        await EmergencyCooldownService.saveLastEmergencyTime();
        _lastEmergencyTime = DateTime.now();

        final emergencyCase = EmergencyCase.fromJson(responseData['data']);
        _activeCase = emergencyCase;
        _myCases.insert(0, emergencyCase);
        _setReporting(false);
        notifyListeners();
        return true;
      } else {
        _setError(responseData['message'] ?? 'Failed to report emergency');
        _setReporting(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      _setReporting(false);
      return false;
    }
  }

  // Report emergency anonymously (public endpoint, no authentication)
  Future<bool> reportPublicEmergency({
    required double latitude,
    required double longitude,
    required EmergencyCategory category,
    required String description,
    String? phone,
    double? accuracy,
  }) async {
    _setReporting(true);
    _clearError();

    try {
      // Check cooldown using persistent storage
      final canReport = await EmergencyCooldownService.canReportEmergency();
      if (!canReport) {
        final remaining =
            await EmergencyCooldownService.getRemainingCooldownMinutes();
        _setError(
            'Please wait $remaining minutes before reporting another emergency');
        _setReporting(false);
        return false;
      }

      // Prepare request data for public endpoint
      Map<String, dynamic> requestData = {
        'latitude': latitude,
        'longitude': longitude,
        'category': category.toString().split('.').last,
        'description': description,
        'website': '', // Honeypot field for bot detection
      };

      // Optional fields
      if (phone != null && phone.isNotEmpty && phone != 'guest-emergency') {
        requestData['phone'] = phone;
      }
      if (accuracy != null) {
        requestData['accuracy'] = accuracy.toInt();
      }

      // Debug: Print request data
      print('=== Public Emergency Report Request ===');
      print('URL: ${ApiConfig.baseUrl}/public/emergency');
      print('Body: ${jsonEncode(requestData)}');
      print('=======================================');

      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/public/emergency'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              'Request timeout - server tidak merespon dalam 15 detik');
        },
      );

      // Debug: Print response
      print('=== Public Emergency Report Response ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('========================================');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        // Set last emergency time for cooldown (persistent)
        await EmergencyCooldownService.saveLastEmergencyTime();
        _lastEmergencyTime = DateTime.now();
        _setReporting(false);
        notifyListeners();
        return true;
      } else if (response.statusCode == 429) {
        _setError('Too many attempts. Please wait a moment and try again.');
        _setReporting(false);
        return false;
      } else {
        _setError(responseData['message'] ?? 'Failed to report emergency');
        _setReporting(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      _setReporting(false);
      return false;
    }
  }

  // Get my cases
  Future<void> getMyCases() async {
    _setLoading(true);
    _clearError();

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _setError('Authentication required');
        _setLoading(false);
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.myCases),
        headers: ApiConfig.authHeaders(token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> casesData = responseData['data'] ?? [];
        _myCases = casesData
            .map((caseJson) => EmergencyCase.fromJson(caseJson))
            .toList();
        _setLoading(false);
        notifyListeners();
      } else {
        _setError(responseData['message'] ?? 'Failed to load cases');
        _setLoading(false);
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Get case details
  Future<EmergencyCase?> getCaseDetails(String caseId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _setError('Authentication required');
        return null;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.emergencyCase(caseId)),
        headers: ApiConfig.authHeaders(token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return EmergencyCase.fromJson(responseData['data']);
      } else {
        _setError(responseData['message'] ?? 'Failed to load case details');
        return null;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return null;
    }
  }

  // For officers - Get assigned cases
  Future<void> getAssignedCases() async {
    _setLoading(true);
    _clearError();

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _setError('Authentication required');
        _setLoading(false);
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.assignedCases),
        headers: ApiConfig.authHeaders(token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> casesData = responseData['data'] ?? [];
        _cases = casesData
            .map((caseJson) => EmergencyCase.fromJson(caseJson))
            .toList();
        _setLoading(false);
        notifyListeners();
      } else {
        _setError(responseData['message'] ?? 'Failed to load assigned cases');
        _setLoading(false);
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Update case status (for officers)
  Future<bool> updateCaseStatus(String caseId, EmergencyStatus status) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _setError('Authentication required');
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.caseStatus(caseId)),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'status': status.toString().split('.').last,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Update local case data
        final caseIndex = _cases.indexWhere((c) => c.id == caseId);
        if (caseIndex != -1) {
          _cases[caseIndex] = _cases[caseIndex].copyWith(status: status);
        }

        // Update active case if it matches
        if (_activeCase?.id == caseId) {
          _activeCase = _activeCase!.copyWith(status: status);
        }

        notifyListeners();
        return true;
      } else {
        _setError(responseData['message'] ?? 'Failed to update case status');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    }
  }

  // Add case note (for officers)
  Future<bool> addCaseNote(String caseId, String note) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _setError('Authentication required');
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.caseNote(caseId)),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'note': note,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        // Refresh case details to get updated notes
        final updatedCase = await getCaseDetails(caseId);
        if (updatedCase != null) {
          final caseIndex = _cases.indexWhere((c) => c.id == caseId);
          if (caseIndex != -1) {
            _cases[caseIndex] = updatedCase;
          }

          if (_activeCase?.id == caseId) {
            _activeCase = updatedCase;
          }

          notifyListeners();
        }
        return true;
      } else {
        _setError(responseData['message'] ?? 'Failed to add note');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    }
  }

  // Set active case
  void setActiveCase(EmergencyCase? emergencyCase) {
    _activeCase = emergencyCase;
    notifyListeners();
  }

  // Get emergency categories for UI
  List<EmergencyCategory> getEmergencyCategories() {
    return EmergencyCategory.values;
  }

  // Get category display info
  Map<String, dynamic> getCategoryInfo(EmergencyCategory category) {
    switch (category) {
      case EmergencyCategory.UMUM:
        return {
          'name': 'Umum',
          'icon': '🚨',
          'color': 0xFFDC2626,
          'description': 'Situasi darurat umum yang memerlukan bantuan segera'
        };
      case EmergencyCategory.BENCANA_ALAM:
        return {
          'name': 'Bencana Alam',
          'icon': '🌪️',
          'color': 0xFFB45309,
          'description': 'Gempa, tsunami, gunung meletus, dll'
        };
      case EmergencyCategory.KECELAKAAN:
        return {
          'name': 'Kecelakaan',
          'icon': '🚗',
          'color': 0xFFDC2626,
          'description': 'Kecelakaan lalu lintas atau kecelakaan kerja'
        };
      case EmergencyCategory.KEBOCORAN_GAS:
        return {
          'name': 'Kebocoran Gas',
          'icon': '⛽',
          'color': 0xFF059669,
          'description': 'Kebocoran gas atau bahaya kimia'
        };
      case EmergencyCategory.POHON_TUMBANG:
        return {
          'name': 'Pohon Tumbang',
          'icon': '🌳',
          'color': 0xFF0891B2,
          'description': 'Pohon tumbang menghalangi jalan'
        };
      case EmergencyCategory.BANJIR:
        return {
          'name': 'Banjir',
          'icon': '🌊',
          'color': 0xFF3B82F6,
          'description': 'Banjir atau genangan air'
        };
      case EmergencyCategory.SAKIT:
        return {
          'name': 'Sakit',
          'icon': '🏥',
          'color': 0xFF059669,
          'description': 'Kondisi sakit yang memerlukan bantuan medis'
        };
      case EmergencyCategory.MEDIS:
        return {
          'name': 'Darurat Medis',
          'icon': '🚑',
          'color': 0xFFEF4444,
          'description': 'Darurat medis yang memerlukan penanganan segera'
        };
    }
  }

  // Get status color
  int getStatusColor(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.NEW:
        return 0xFF6B7280;
      case EmergencyStatus.PENDING:
        return 0xFFF59E0B;
      case EmergencyStatus.VERIFIED:
        return 0xFF3B82F6;
      case EmergencyStatus.DISPATCHED:
        return 0xFF8B5CF6;
      case EmergencyStatus.ON_THE_WAY:
        return 0xFF06B6D4;
      case EmergencyStatus.ON_SCENE:
        return 0xFFEF4444;
      case EmergencyStatus.RESOLVED:
        return 0xFF10B981;
      case EmergencyStatus.CANCELLED:
        return 0xFF6B7280;
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setReporting(bool reporting) {
    _isReporting = reporting;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Clear all data
  void clearData() {
    _cases.clear();
    _myCases.clear();
    _activeCase = null;
    _errorMessage = null;
    notifyListeners();
  }
}
