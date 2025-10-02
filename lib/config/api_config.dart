class ApiConfig {
  static const String baseUrl = 'http://safepoint.my.id/api';

  // Auth endpoints
  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String petugasLogin = '$baseUrl/petugas/login';
  static const String logout = '$baseUrl/logout';
  static const String me = '$baseUrl/me';

  // Citizen endpoints
  static const String profile = '$baseUrl/profile';
  static const String emergency = '$baseUrl/emergency';
  static const String myCases = '$baseUrl/my-cases';

  // Officer endpoints
  static const String petugasProfile = '$baseUrl/petugas/profile';
  static const String dutyStart = '$baseUrl/petugas/duty/start';
  static const String dutyEnd = '$baseUrl/petugas/duty/end';
  static const String dutyStatus = '$baseUrl/petugas/duty/status';
  static const String updateLocation = '$baseUrl/petugas/location/update';
  static const String currentLocation = '$baseUrl/petugas/location/current';
  static const String assignedCases = '$baseUrl/petugas/cases/assigned';
  static const String dashboard = '$baseUrl/petugas/dashboard';

  // Case management
  static String emergencyCase(String caseId) => '$baseUrl/emergency/$caseId';
  static String petugasCase(String caseId) => '$baseUrl/petugas/cases/$caseId';
  static String caseStatus(String caseId) =>
      '$baseUrl/petugas/cases/$caseId/status';
  static String caseNote(String caseId) =>
      '$baseUrl/petugas/cases/$caseId/note';
  static String familyContacts(String caseId) =>
      '$baseUrl/petugas/cases/$caseId/family-contacts';
  static String contactFamily(String caseId) =>
      '$baseUrl/petugas/cases/$caseId/contact-family';

  // Headers
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };
}
