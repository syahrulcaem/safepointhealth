import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/my_case.dart';
import 'auth_service.dart';

class MyCasesService {
  /// Mendapatkan daftar kasus user dengan pagination
  ///
  /// [page] - Halaman yang ingin diambil (default: 1)
  ///
  /// Returns MyCasesResponse dengan data cases dan pagination info
  static Future<MyCasesResponse?> getMyCases({int page = 1}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/my-cases').replace(
        queryParameters: {'page': page.toString()},
      );

      print('=== Get My Cases Request ===');
      print('URL: $uri');
      print('Page: $page');

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      print('=== Get My Cases Response ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('===========================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return MyCasesResponse.fromJson(data['data']);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting my cases: $e');
      rethrow;
    }
  }

  /// Refresh cases - alias untuk getMyCases page 1
  static Future<MyCasesResponse?> refreshCases() async {
    return getMyCases(page: 1);
  }

  /// Get single case detail by ID (jika API tersedia)
  static Future<MyCase?> getCaseDetail(String caseId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/cases/$caseId'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return MyCase.fromJson(data['data']);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting case detail: $e');
      return null;
    }
  }
}
