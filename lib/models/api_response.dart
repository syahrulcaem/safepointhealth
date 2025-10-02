import 'user.dart';
import 'emergency_case.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'],
      statusCode: json['status_code'],
    );
  }

  factory ApiResponse.success({
    String? message,
    T? data,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode ?? 200,
    );
  }

  factory ApiResponse.error({
    String? message,
    Map<String, dynamic>? errors,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
      statusCode: statusCode ?? 400,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors,
      'status_code': statusCode,
    };
  }
}

class LoginResponse {
  final String token;
  final String tokenType;
  final User user;

  LoginResponse({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}

class DashboardData {
  final int totalCases;
  final int activeCases;
  final int resolvedCases;
  final int pendingCases;
  final List<EmergencyCase> recentCases;

  DashboardData({
    required this.totalCases,
    required this.activeCases,
    required this.resolvedCases,
    required this.pendingCases,
    required this.recentCases,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalCases: json['total_cases'] ?? 0,
      activeCases: json['active_cases'] ?? 0,
      resolvedCases: json['resolved_cases'] ?? 0,
      pendingCases: json['pending_cases'] ?? 0,
      recentCases: json['recent_cases'] != null
          ? (json['recent_cases'] as List)
              .map((caseJson) => EmergencyCase.fromJson(caseJson))
              .toList()
          : [],
    );
  }
}
