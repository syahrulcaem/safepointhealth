class ApiConfig {
  static const String baseUrl = 'http://safepoint.my.id/api';

  // Auth endpoints
  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String petugasLogin = '$baseUrl/petugas/login';
  static const String petugasLogout = '$baseUrl/petugas/logout';
  static const String logout = '$baseUrl/logout';
  static const String me = '$baseUrl/me';

  // Citizen endpoints
  static const String profile = '$baseUrl/profile';
  static const String emergency = '$baseUrl/emergency';
  static const String myCases = '$baseUrl/my-cases';

  // Officer endpoints - Authentication
  static const String petugasProfile = '$baseUrl/petugas/profile';

  // Officer endpoints - Case Management
  static const String assignedCases = '$baseUrl/petugas/cases/assigned';
  static String petugasCase(String caseId) => '$baseUrl/petugas/cases/$caseId';
  static String caseStatus(String caseId) =>
      '$baseUrl/petugas/cases/$caseId/status';
  static String closeCase(String caseId) =>
      '$baseUrl/petugas/cases/$caseId/close';

  // Officer endpoints - Notifications
  static const String newAssignments = '$baseUrl/petugas/cases/new-assignments';
  static const String unreadCount =
      '$baseUrl/petugas/notifications/unread-count';
  static const String checkUpdates = '$baseUrl/petugas/check-updates';

  // Officer endpoints - Location Tracking
  static const String updateLocation = '$baseUrl/petugas/location/update';
  static const String currentLocation = '$baseUrl/petugas/location/current';

  // Officer endpoints - What3Words
  static const String what3words = '$baseUrl/petugas/location/what3words';
  static const String coordinates = '$baseUrl/petugas/location/coordinates';

  // Officer endpoints - Legacy
  static const String dutyStart = '$baseUrl/petugas/duty/start';
  static const String dutyEnd = '$baseUrl/petugas/duty/end';
  static const String dutyStatus = '$baseUrl/petugas/duty/status';
  static const String dashboard = '$baseUrl/petugas/dashboard';

  // Case management (Legacy)
  static String emergencyCase(String caseId) => '$baseUrl/emergency/$caseId';
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
