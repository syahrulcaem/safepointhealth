import 'user.dart';

enum EmergencyCategory {
  UMUM,
  BENCANA_ALAM,
  KECELAKAAN,
  KEBOCORAN_GAS,
  POHON_TUMBANG,
  BANJIR,
  SAKIT,
  MEDIS
}

enum EmergencyStatus {
  NEW,
  PENDING,
  VERIFIED,
  DISPATCHED,
  ON_THE_WAY,
  ON_SCENE,
  RESOLVED,
  CANCELLED
}

class ContactSnapshot {
  final String name;
  final String phone;
  final String relation;
  final bool isPrimary;

  ContactSnapshot({
    required this.name,
    required this.phone,
    required this.relation,
    required this.isPrimary,
  });

  factory ContactSnapshot.fromJson(Map<String, dynamic> json) {
    return ContactSnapshot(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
      'is_primary': isPrimary,
    };
  }
}

class CaseEvent {
  final int id;
  final String action;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final User? actor;

  CaseEvent({
    required this.id,
    required this.action,
    this.metadata,
    required this.createdAt,
    this.actor,
  });

  factory CaseEvent.fromJson(Map<String, dynamic> json) {
    return CaseEvent(
      id: json['id'] as int,
      action: json['action']?.toString() ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      actor: json['actor'] != null ? User.fromJson(json['actor']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'actor': actor?.toJson(),
    };
  }
}

class Dispatch {
  final int id;
  final Unit unit;
  final User assignedBy;
  final DateTime createdAt;

  Dispatch({
    required this.id,
    required this.unit,
    required this.assignedBy,
    required this.createdAt,
  });

  factory Dispatch.fromJson(Map<String, dynamic> json) {
    return Dispatch(
      id: json['id'] as int,
      unit: Unit.fromJson(json['unit']),
      assignedBy: User.fromJson(json['assigned_by']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit': unit.toJson(),
      'assigned_by': assignedBy.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class EmergencyCase {
  final String id;
  final String reporterUserId;
  final String? deviceId;
  final String viewerTokenHash;
  final String? phone;
  final double lat;
  final double lon;
  final int? accuracy;
  final String? locatorText;
  final String locatorProvider;
  final EmergencyCategory category;
  final EmergencyStatus status;
  final String? description;
  final String? assignedUnitId;
  final String? assignedPetugasId;
  final List<ContactSnapshot> contactsSnapshot;
  final DateTime? verifiedAt;
  final DateTime? dispatchedAt;
  final DateTime? onSceneAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? reporterUser;
  final Unit? assignedUnit;
  final List<CaseEvent>? caseEvents;
  final List<Dispatch>? dispatches;

  EmergencyCase({
    required this.id,
    required this.reporterUserId,
    this.deviceId,
    required this.viewerTokenHash,
    this.phone,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.locatorText,
    required this.locatorProvider,
    required this.category,
    required this.status,
    this.description,
    this.assignedUnitId,
    this.assignedPetugasId,
    required this.contactsSnapshot,
    this.verifiedAt,
    this.dispatchedAt,
    this.onSceneAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    this.reporterUser,
    this.assignedUnit,
    this.caseEvents,
    this.dispatches,
  });

  factory EmergencyCase.fromJson(Map<String, dynamic> json) {
    return EmergencyCase(
      id: json['id']?.toString() ?? '',
      reporterUserId: json['reporter_user_id']?.toString() ?? '',
      deviceId: json['device_id']?.toString(),
      viewerTokenHash: json['viewer_token_hash']?.toString() ?? '',
      phone: json['phone']?.toString(),
      lat: double.parse(json['lat']?.toString() ?? '0.0'),
      lon: double.parse(json['lon']?.toString() ?? '0.0'),
      accuracy: json['accuracy'] as int?,
      locatorText: json['locator_text']?.toString(),
      locatorProvider: json['locator_provider']?.toString() ?? 'coordinates',
      category: EmergencyCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => EmergencyCategory.UMUM,
      ),
      status: EmergencyStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => EmergencyStatus.NEW,
      ),
      description: json['description']?.toString(),
      assignedUnitId: json['assigned_unit_id']?.toString(),
      assignedPetugasId: json['assigned_petugas_id']?.toString(),
      contactsSnapshot: json['contacts_snapshot'] != null
          ? (json['contacts_snapshot'] as List)
              .map((contact) => ContactSnapshot.fromJson(contact))
              .toList()
          : [],
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
      reporterUser: json['reporter_user'] != null
          ? User.fromJson(json['reporter_user'])
          : null,
      assignedUnit: json['assigned_unit'] != null
          ? Unit.fromJson(json['assigned_unit'])
          : null,
      caseEvents: json['case_events'] != null
          ? (json['case_events'] as List)
              .map((event) => CaseEvent.fromJson(event))
              .toList()
          : null,
      dispatches: json['dispatches'] != null
          ? (json['dispatches'] as List)
              .map((dispatch) => Dispatch.fromJson(dispatch))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_user_id': reporterUserId,
      'device_id': deviceId,
      'viewer_token_hash': viewerTokenHash,
      'phone': phone,
      'lat': lat.toString(),
      'lon': lon.toString(),
      'accuracy': accuracy,
      'locator_text': locatorText,
      'locator_provider': locatorProvider,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'assigned_unit_id': assignedUnitId,
      'assigned_petugas_id': assignedPetugasId,
      'contacts_snapshot':
          contactsSnapshot.map((contact) => contact.toJson()).toList(),
      'verified_at': verifiedAt?.toIso8601String(),
      'dispatched_at': dispatchedAt?.toIso8601String(),
      'on_scene_at': onSceneAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reporter_user': reporterUser?.toJson(),
      'assigned_unit': assignedUnit?.toJson(),
      'case_events': caseEvents?.map((event) => event.toJson()).toList(),
      'dispatches': dispatches?.map((dispatch) => dispatch.toJson()).toList(),
    };
  }

  EmergencyCase copyWith({
    String? id,
    String? reporterUserId,
    String? deviceId,
    String? viewerTokenHash,
    String? phone,
    double? lat,
    double? lon,
    int? accuracy,
    String? locatorText,
    String? locatorProvider,
    EmergencyCategory? category,
    EmergencyStatus? status,
    String? description,
    String? assignedUnitId,
    String? assignedPetugasId,
    List<ContactSnapshot>? contactsSnapshot,
    DateTime? verifiedAt,
    DateTime? dispatchedAt,
    DateTime? onSceneAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? reporterUser,
    Unit? assignedUnit,
    List<CaseEvent>? caseEvents,
    List<Dispatch>? dispatches,
  }) {
    return EmergencyCase(
      id: id ?? this.id,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      deviceId: deviceId ?? this.deviceId,
      viewerTokenHash: viewerTokenHash ?? this.viewerTokenHash,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      accuracy: accuracy ?? this.accuracy,
      locatorText: locatorText ?? this.locatorText,
      locatorProvider: locatorProvider ?? this.locatorProvider,
      category: category ?? this.category,
      status: status ?? this.status,
      description: description ?? this.description,
      assignedUnitId: assignedUnitId ?? this.assignedUnitId,
      assignedPetugasId: assignedPetugasId ?? this.assignedPetugasId,
      contactsSnapshot: contactsSnapshot ?? this.contactsSnapshot,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      onSceneAt: onSceneAt ?? this.onSceneAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reporterUser: reporterUser ?? this.reporterUser,
      assignedUnit: assignedUnit ?? this.assignedUnit,
      caseEvents: caseEvents ?? this.caseEvents,
      dispatches: dispatches ?? this.dispatches,
    );
  }

  // Getters for display names
  String get categoryDisplayName {
    switch (category) {
      case EmergencyCategory.UMUM:
        return 'Darurat Umum';
      case EmergencyCategory.BENCANA_ALAM:
        return 'Bencana Alam';
      case EmergencyCategory.KECELAKAAN:
        return 'Kecelakaan';
      case EmergencyCategory.KEBOCORAN_GAS:
        return 'Kebocoran Gas';
      case EmergencyCategory.POHON_TUMBANG:
        return 'Pohon Tumbang';
      case EmergencyCategory.BANJIR:
        return 'Banjir';
      case EmergencyCategory.SAKIT:
        return 'Sakit/Medis';
      case EmergencyCategory.MEDIS:
        return 'Darurat Medis';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case EmergencyStatus.NEW:
        return 'Baru';
      case EmergencyStatus.PENDING:
        return 'Menunggu';
      case EmergencyStatus.VERIFIED:
        return 'Terverifikasi';
      case EmergencyStatus.DISPATCHED:
        return 'Dikirim';
      case EmergencyStatus.ON_THE_WAY:
        return 'Dalam Perjalanan';
      case EmergencyStatus.ON_SCENE:
        return 'Di Lokasi';
      case EmergencyStatus.RESOLVED:
        return 'Selesai';
      case EmergencyStatus.CANCELLED:
        return 'Dibatalkan';
    }
  }
}
