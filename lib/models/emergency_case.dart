class EmergencyCase {
  final String id;
  final String? shortId;
  final String? reporterUserId;
  final String? deviceId;
  final String? viewerTokenHash;
  final String? phone;
  final double lat;
  final double lon;
  final double? accuracy;
  final String? locatorText;
  final String? locatorProvider;
  final String? location;
  final EmergencyCategory category;
  final EmergencyStatus status;
  final String description;
  final String? assignedUnitId;
  final String? assignedPetugasId;
  final List<dynamic>? contactsSnapshot;
  final DateTime? verifiedAt;
  final DateTime? dispatchedAt;
  final DateTime? onSceneAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? photos;
  final String? audioRecord;
  final List<CaseNote>? notes;
  final ReporterUser? reporterUser;
  final List<dynamic>? dispatches;
  final List<CaseEvent>? caseEvents;

  EmergencyCase({
    required this.id,
    this.shortId,
    this.reporterUserId,
    this.deviceId,
    this.viewerTokenHash,
    this.phone,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.locatorText,
    this.locatorProvider,
    this.location,
    required this.category,
    required this.status,
    required this.description,
    this.assignedUnitId,
    this.assignedPetugasId,
    this.contactsSnapshot,
    this.verifiedAt,
    this.dispatchedAt,
    this.onSceneAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    this.photos,
    this.audioRecord,
    this.notes,
    this.reporterUser,
    this.dispatches,
    this.caseEvents,
  });

  factory EmergencyCase.fromJson(Map<String, dynamic> json) {
    // Parse lat/lon from string or number
    double parseLat(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double parseLon(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return EmergencyCase(
      id: json['id']?.toString() ?? '',
      shortId: json['short_id']?.toString(),
      reporterUserId: json['reporter_user_id']?.toString(),
      deviceId: json['device_id']?.toString(),
      viewerTokenHash: json['viewer_token_hash']?.toString(),
      phone: json['phone']?.toString(),
      lat: parseLat(json['lat']),
      lon: parseLon(json['lon']),
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] is String
              ? double.tryParse(json['accuracy'])
              : (json['accuracy'] as num?)?.toDouble())
          : null,
      locatorText: json['locator_text'],
      locatorProvider: json['locator_provider'],
      location: json['location'],
      category: EmergencyCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => EmergencyCategory.DARURAT,
      ),
      status: EmergencyStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => EmergencyStatus.PENDING,
      ),
      description: json['description'] ?? '',
      assignedUnitId: json['assigned_unit_id']?.toString(),
      assignedPetugasId: json['assigned_petugas_id']?.toString(),
      contactsSnapshot: json['contacts_snapshot'],
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.parse(json['dispatched_at'])
          : null,
      onSceneAt: json['on_scene_at'] != null
          ? DateTime.parse(json['on_scene_at'])
          : null,
      closedAt:
          json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      photos: json['photos'] != null ? List<String>.from(json['photos']) : null,
      audioRecord: json['audio_record'],
      notes: json['notes'] != null
          ? (json['notes'] as List)
              .map((note) => CaseNote.fromJson(note))
              .toList()
          : null,
      reporterUser: json['reporter_user'] != null
          ? ReporterUser.fromJson(json['reporter_user'])
          : null,
      dispatches: json['dispatches'],
      caseEvents: json['case_events'] != null
          ? (json['case_events'] as List)
              .map((event) => CaseEvent.fromJson(event))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_user_id': reporterUserId,
      'phone': phone,
      'lat': lat,
      'lon': lon,
      'accuracy': accuracy,
      'locator_text': locatorText,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'assigned_unit_id': assignedUnitId,
      'assigned_petugas_id': assignedPetugasId,
      'verified_at': verifiedAt?.toIso8601String(),
      'dispatched_at': dispatchedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'photos': photos,
      'audio_record': audioRecord,
      'notes': notes?.map((note) => note.toJson()).toList(),
    };
  }

  EmergencyCase copyWith({
    String? id,
    String? reporterUserId,
    String? phone,
    double? lat,
    double? lon,
    double? accuracy,
    String? locatorText,
    EmergencyCategory? category,
    EmergencyStatus? status,
    String? description,
    String? assignedUnitId,
    String? assignedPetugasId,
    DateTime? verifiedAt,
    DateTime? dispatchedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? photos,
    String? audioRecord,
    List<CaseNote>? notes,
  }) {
    return EmergencyCase(
      id: id ?? this.id,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      accuracy: accuracy ?? this.accuracy,
      locatorText: locatorText ?? this.locatorText,
      category: category ?? this.category,
      status: status ?? this.status,
      description: description ?? this.description,
      assignedUnitId: assignedUnitId ?? this.assignedUnitId,
      assignedPetugasId: assignedPetugasId ?? this.assignedPetugasId,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
      audioRecord: audioRecord ?? this.audioRecord,
      notes: notes ?? this.notes,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case EmergencyStatus.NEW:
        return 'Baru';
      case EmergencyStatus.PENDING:
        return 'Menunggu Verifikasi';
      case EmergencyStatus.VERIFIED:
        return 'Terverifikasi';
      case EmergencyStatus.DISPATCHED:
        return 'Petugas Ditugaskan';
      case EmergencyStatus.ON_THE_WAY:
        return 'Petugas Dalam Perjalanan';
      case EmergencyStatus.ON_SCENE:
        return 'Petugas Di Lokasi';
      case EmergencyStatus.CLOSED:
        return 'Ditutup';
      case EmergencyStatus.RESOLVED:
        return 'Selesai';
      case EmergencyStatus.CANCELLED:
        return 'Dibatalkan';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case EmergencyCategory.DARURAT:
        return 'Darurat';
      case EmergencyCategory.BENCANA_ALAM:
        return 'Bencana Alam';
      case EmergencyCategory.KECELAKAAN:
        return 'Kecelakaan';
      case EmergencyCategory.MEDIS:
        return 'Medis';
      case EmergencyCategory.SAKIT:
        return 'Sakit';
      case EmergencyCategory.KEBAKARAN:
        return 'Kebakaran';
      case EmergencyCategory.POHON_TUMBANG:
        return 'Pohon Tumbang';
      case EmergencyCategory.BANJIR:
        return 'Banjir';
    }
  }
}

enum EmergencyCategory {
  DARURAT,
  BENCANA_ALAM,
  KECELAKAAN,
  MEDIS, // From API
  SAKIT,
  KEBAKARAN, // From API
  POHON_TUMBANG,
  BANJIR,
}

enum EmergencyStatus {
  NEW, // From API
  PENDING,
  VERIFIED,
  DISPATCHED,
  ON_THE_WAY,
  ON_SCENE,
  CLOSED, // From API
  RESOLVED,
  CANCELLED,
}

class CaseNote {
  final String id;
  final String caseId;
  final String userId;
  final String note;
  final DateTime createdAt;

  CaseNote({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.note,
    required this.createdAt,
  });

  factory CaseNote.fromJson(Map<String, dynamic> json) {
    return CaseNote(
      id: json['id'] ?? '',
      caseId: json['case_id'] ?? '',
      userId: json['user_id'] ?? '',
      note: json['note'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'user_id': userId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ReporterUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final int? unitId;
  final String? lastLatitude;
  final String? lastLongitude;
  final DateTime? lastLocationUpdate;
  final String dutyStatus;
  final DateTime? dutyStartedAt;
  final DateTime? lastActivityAt;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic citizenProfile;

  ReporterUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.unitId,
    this.lastLatitude,
    this.lastLongitude,
    this.lastLocationUpdate,
    required this.dutyStatus,
    this.dutyStartedAt,
    this.lastActivityAt,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.citizenProfile,
  });

  factory ReporterUser.fromJson(Map<String, dynamic> json) {
    return ReporterUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      unitId: json['unit_id'],
      lastLatitude: json['last_latitude'],
      lastLongitude: json['last_longitude'],
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'])
          : null,
      dutyStatus: json['duty_status'] ?? '',
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
      citizenProfile: json['citizen_profile'],
    );
  }
}

class CaseEvent {
  final int id;
  final String caseId;
  final String actorType;
  final String? actorId;
  final String action;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  CaseEvent({
    required this.id,
    required this.caseId,
    required this.actorType,
    this.actorId,
    required this.action,
    this.notes,
    this.metadata,
    required this.createdAt,
  });

  factory CaseEvent.fromJson(Map<String, dynamic> json) {
    return CaseEvent(
      id: json['id'] ?? 0,
      caseId: json['case_id'] ?? '',
      actorType: json['actor_type'] ?? '',
      actorId: json['actor_id']?.toString(),
      action: json['action'] ?? '',
      notes: json['notes'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get actionDisplayName {
    switch (action) {
      case 'CREATED':
        return 'Kasus Dibuat';
      case 'CASE_CREATED':
        return 'Kasus Dibuat';
      case 'STATUS_CHANGED':
        return 'Status Berubah';
      case 'DISPATCHED':
        return 'Dikirim ke Unit';
      case 'PETUGAS_ASSIGNED':
        return 'Petugas Ditugaskan';
      case 'CASE_CLOSED':
        return 'Kasus Ditutup';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  String get displayText {
    if (notes != null && notes!.isNotEmpty) {
      return notes!;
    }

    if (metadata != null) {
      if (action == 'STATUS_CHANGED') {
        final oldStatus = metadata!['old_status'] ?? '';
        final newStatus = metadata!['new_status'] ?? '';
        return 'Status berubah dari $oldStatus ke $newStatus';
      }
      if (action == 'CREATED' || action == 'CASE_CREATED') {
        final category = metadata!['category'] ?? '';
        final location = metadata!['location'] ?? metadata!['what3words'] ?? '';
        return 'Kasus $category dibuat${location.isNotEmpty ? ' di $location' : ''}';
      }
    }

    return actionDisplayName;
  }
}
