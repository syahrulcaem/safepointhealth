import 'citizen_profile.dart';

enum UserRole { WARGA, PETUGAS, ADMIN }

enum DutyStatus { ON_DUTY, OFF_DUTY }

class Unit {
  final String id;
  final String name;
  final String type;
  final bool isActive;
  final double? lastLat;
  final double? lastLon;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Unit({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    this.lastLat,
    this.lastLon,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
      lastLat: json['last_lat'] != null
          ? double.tryParse(json['last_lat'].toString())
          : null,
      lastLon: json['last_lon'] != null
          ? double.tryParse(json['last_lon'].toString())
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'is_active': isActive,
      'last_lat': lastLat,
      'last_lon': lastLon,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class User {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final UserRole role;
  final String? unitId;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastLocationUpdate;
  final DutyStatus? dutyStatus;
  final DateTime? dutyStartedAt;
  final DateTime? lastActivityAt;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CitizenProfile? citizenProfile;
  final Unit? unit;

  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.unitId,
    this.lastLatitude,
    this.lastLongitude,
    this.lastLocationUpdate,
    this.dutyStatus,
    this.dutyStartedAt,
    this.lastActivityAt,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.citizenProfile,
    this.unit,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing User from JSON: $json');

    try {
      return User(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        role: UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == json['role'],
          orElse: () => UserRole.WARGA,
        ),
        unitId: json['unit_id']?.toString(),
        lastLatitude: json['last_latitude'] != null
            ? double.tryParse(json['last_latitude'].toString())
            : null,
        lastLongitude: json['last_longitude'] != null
            ? double.tryParse(json['last_longitude'].toString())
            : null,
        lastLocationUpdate: json['last_location_update'] != null
            ? DateTime.parse(json['last_location_update'])
            : null,
        dutyStatus: json['duty_status'] != null
            ? DutyStatus.values.firstWhere(
                (e) => e.toString().split('.').last == json['duty_status'],
                orElse: () => DutyStatus.OFF_DUTY,
              )
            : null,
        dutyStartedAt: json['duty_started_at'] != null
            ? DateTime.parse(json['duty_started_at'])
            : null,
        lastActivityAt: json['last_activity_at'] != null
            ? DateTime.parse(json['last_activity_at'])
            : null,
        emailVerifiedAt: json['email_verified_at'] != null
            ? DateTime.parse(json['email_verified_at'])
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
        citizenProfile: json['citizen_profile'] != null
            ? CitizenProfile.fromJson(json['citizen_profile'])
            : null,
        unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      );
    } catch (e) {
      print('Error parsing User: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'unit_id': unitId,
      'last_latitude': lastLatitude,
      'last_longitude': lastLongitude,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
      'duty_status': dutyStatus?.toString().split('.').last,
      'duty_started_at': dutyStartedAt?.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'citizen_profile': citizenProfile?.toJson(),
      'unit': unit?.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? unitId,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? lastLocationUpdate,
    DutyStatus? dutyStatus,
    DateTime? dutyStartedAt,
    DateTime? lastActivityAt,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    CitizenProfile? citizenProfile,
    Unit? unit,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      unitId: unitId ?? this.unitId,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      dutyStatus: dutyStatus ?? this.dutyStatus,
      dutyStartedAt: dutyStartedAt ?? this.dutyStartedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      citizenProfile: citizenProfile ?? this.citizenProfile,
      unit: unit ?? this.unit,
    );
  }
}
