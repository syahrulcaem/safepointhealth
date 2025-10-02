class EmergencyCase {
  final String id;
  final String reporterUserId;
  final String phone;
  final double lat;
  final double lon;
  final double? accuracy;
  final String? locatorText;
  final EmergencyCategory category;
  final EmergencyStatus status;
  final String description;
  final String? assignedUnitId;
  final String? assignedPetugasId;
  final DateTime? verifiedAt;
  final DateTime? dispatchedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? photos;
  final String? audioRecord;
  final List<CaseNote>? notes;

  EmergencyCase({
    required this.id,
    required this.reporterUserId,
    required this.phone,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.locatorText,
    required this.category,
    required this.status,
    required this.description,
    this.assignedUnitId,
    this.assignedPetugasId,
    this.verifiedAt,
    this.dispatchedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    this.photos,
    this.audioRecord,
    this.notes,
  });

  factory EmergencyCase.fromJson(Map<String, dynamic> json) {
    return EmergencyCase(
      id: json['id']?.toString() ?? '',
      reporterUserId: json['reporter_user_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      locatorText: json['locator_text'],
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
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.parse(json['dispatched_at'])
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
      case EmergencyCategory.SAKIT:
        return 'Medis/Sakit';
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
  SAKIT,
  POHON_TUMBANG,
  BANJIR,
}

enum EmergencyStatus {
  PENDING,
  VERIFIED,
  DISPATCHED,
  ON_THE_WAY,
  ON_SCENE,
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
