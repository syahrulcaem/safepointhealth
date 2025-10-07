import 'emergency_case_new.dart';

/// Model untuk My Cases (Riwayat laporan darurat user)
class MyCase {
  final String id;
  final String shortId;
  final String reporterUserId;
  final String? deviceId;
  final String viewerTokenHash;
  final String phone;
  final double lat;
  final double lon;
  final double accuracy;
  final String locatorText;
  final String locatorProvider;
  final EmergencyCategory category;
  final String? description;
  final String? location;
  final EmergencyStatus status;
  final int? assignedUnitId;
  final int? assignedPetugasId;
  final List<dynamic> contactsSnapshot;
  final DateTime? dispatchedAt;
  final DateTime? onSceneAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AssignedUnit? assignedUnit;

  MyCase({
    required this.id,
    required this.shortId,
    required this.reporterUserId,
    this.deviceId,
    required this.viewerTokenHash,
    required this.phone,
    required this.lat,
    required this.lon,
    required this.accuracy,
    required this.locatorText,
    required this.locatorProvider,
    required this.category,
    this.description,
    this.location,
    required this.status,
    this.assignedUnitId,
    this.assignedPetugasId,
    required this.contactsSnapshot,
    this.dispatchedAt,
    this.onSceneAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    this.assignedUnit,
  });

  factory MyCase.fromJson(Map<String, dynamic> json) {
    return MyCase(
      id: json['id'] as String,
      shortId: json['short_id'] as String,
      reporterUserId: json['reporter_user_id']?.toString() ?? '',
      deviceId: json['device_id']?.toString(),
      viewerTokenHash: json['viewer_token_hash'] as String,
      phone: json['phone'] as String,
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      accuracy: double.tryParse(json['accuracy']?.toString() ?? '0') ?? 0.0,
      locatorText: json['locator_text'] as String? ?? '',
      locatorProvider: json['locator_provider'] as String? ?? 'w3w',
      category: _parseCategory(json['category']),
      description: json['description'] as String?,
      location: json['location'] as String?,
      status: _parseStatus(json['status']),
      assignedUnitId: json['assigned_unit_id'] as int?,
      assignedPetugasId: json['assigned_petugas_id'] as int?,
      contactsSnapshot: json['contacts_snapshot'] as List<dynamic>? ?? [],
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.parse(json['dispatched_at'] as String)
          : null,
      onSceneAt: json['on_scene_at'] != null
          ? DateTime.parse(json['on_scene_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assignedUnit: json['assigned_unit'] != null
          ? AssignedUnit.fromJson(json['assigned_unit'] as Map<String, dynamic>)
          : null,
    );
  }

  static EmergencyCategory _parseCategory(dynamic category) {
    if (category == null) return EmergencyCategory.UMUM;

    final categoryStr = category.toString().toUpperCase();
    switch (categoryStr) {
      case 'MEDIS':
        return EmergencyCategory.MEDIS;
      case 'KEBAKARAN':
        return EmergencyCategory
            .UMUM; // Map KEBAKARAN ke UMUM (tidak ada di enum)
      case 'KECELAKAAN':
        return EmergencyCategory.KECELAKAAN;
      case 'KRIMINAL':
        return EmergencyCategory.UMUM; // Map KRIMINAL ke UMUM
      case 'BENCANA':
        return EmergencyCategory.BENCANA_ALAM;
      case 'UMUM':
        return EmergencyCategory.UMUM;
      default:
        return EmergencyCategory.UMUM;
    }
  }

  static EmergencyStatus _parseStatus(dynamic status) {
    if (status == null) return EmergencyStatus.PENDING;

    final statusStr = status.toString().toUpperCase();
    switch (statusStr) {
      case 'PENDING':
        return EmergencyStatus.PENDING;
      case 'DISPATCHED':
        return EmergencyStatus.DISPATCHED;
      case 'ON_THE_WAY':
        return EmergencyStatus.ON_THE_WAY;
      case 'ON_SCENE':
        return EmergencyStatus.ON_SCENE;
      case 'CLOSED':
        return EmergencyStatus
            .RESOLVED; // Map CLOSED ke RESOLVED (tidak ada CLOSED)
      case 'CANCELLED':
        return EmergencyStatus.CANCELLED;
      default:
        return EmergencyStatus.PENDING;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'short_id': shortId,
      'reporter_user_id': reporterUserId,
      'device_id': deviceId,
      'viewer_token_hash': viewerTokenHash,
      'phone': phone,
      'lat': lat.toString(),
      'lon': lon.toString(),
      'accuracy': accuracy.toString(),
      'locator_text': locatorText,
      'locator_provider': locatorProvider,
      'category': category.toString().split('.').last,
      'description': description,
      'location': location,
      'status': status.toString().split('.').last,
      'assigned_unit_id': assignedUnitId,
      'assigned_petugas_id': assignedPetugasId,
      'contacts_snapshot': contactsSnapshot,
      'dispatched_at': dispatchedAt?.toIso8601String(),
      'on_scene_at': onSceneAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'assigned_unit': assignedUnit?.toJson(),
    };
  }
}

/// Model untuk Assigned Unit
class AssignedUnit {
  final int id;
  final String name;
  final String? type;
  final String? address;
  final String? phone;

  AssignedUnit({
    required this.id,
    required this.name,
    this.type,
    this.address,
    this.phone,
  });

  factory AssignedUnit.fromJson(Map<String, dynamic> json) {
    return AssignedUnit(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'phone': phone,
    };
  }
}

/// Response wrapper untuk My Cases API
class MyCasesResponse {
  final bool success;
  final MyCasesPagination cases;

  MyCasesResponse({
    required this.success,
    required this.cases,
  });

  factory MyCasesResponse.fromJson(Map<String, dynamic> json) {
    return MyCasesResponse(
      success: true,
      cases: MyCasesPagination.fromJson(json['cases'] as Map<String, dynamic>),
    );
  }
}

/// Pagination untuk My Cases
class MyCasesPagination {
  final int currentPage;
  final List<MyCase> data;
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final String? nextPageUrl;
  final String? path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  MyCasesPagination({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    this.nextPageUrl,
    this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory MyCasesPagination.fromJson(Map<String, dynamic> json) {
    return MyCasesPagination(
      currentPage: json['current_page'] as int,
      data: (json['data'] as List<dynamic>)
          .map((item) => MyCase.fromJson(item as Map<String, dynamic>))
          .toList(),
      firstPageUrl: json['first_page_url'] as String?,
      from: json['from'] as int?,
      lastPage: json['last_page'] as int,
      lastPageUrl: json['last_page_url'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      path: json['path'] as String?,
      perPage: json['per_page'] as int,
      prevPageUrl: json['prev_page_url'] as String?,
      to: json['to'] as int?,
      total: json['total'] as int,
    );
  }
}
