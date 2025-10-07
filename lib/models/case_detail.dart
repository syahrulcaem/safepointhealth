/// Model untuk detail kasus lengkap dari API Petugas
/// Sesuai dengan response GET /petugas/cases/{case_id}
class CaseDetail {
  final String id;
  final String shortId;
  final String category;
  final String status;
  final String description;
  final CaseLocation location;
  final CaseReporter? reporter;
  final CaseNavigation? navigation;
  final List<CaseTimeline> timeline;
  final String createdAt;
  final String createdAtHuman;
  final String? closedAt;

  CaseDetail({
    required this.id,
    required this.shortId,
    required this.category,
    required this.status,
    required this.description,
    required this.location,
    this.reporter,
    this.navigation,
    required this.timeline,
    required this.createdAt,
    required this.createdAtHuman,
    this.closedAt,
  });

  factory CaseDetail.fromJson(Map<String, dynamic> json) {
    return CaseDetail(
      id: json['id']?.toString() ?? '',
      shortId: json['short_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: CaseLocation.fromJson(json['location'] ?? {}),
      reporter: json['reporter'] != null
          ? CaseReporter.fromJson(json['reporter'])
          : null,
      navigation: json['navigation'] != null
          ? CaseNavigation.fromJson(json['navigation'])
          : null,
      timeline: (json['timeline'] as List<dynamic>? ?? [])
          .map((item) => CaseTimeline.fromJson(item))
          .toList(),
      createdAt: json['created_at']?.toString() ?? '',
      createdAtHuman: json['created_at_human']?.toString() ?? '',
      closedAt: json['closed_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'short_id': shortId,
      'category': category,
      'status': status,
      'description': description,
      'location': location.toJson(),
      'reporter': reporter?.toJson(),
      'navigation': navigation?.toJson(),
      'timeline': timeline.map((t) => t.toJson()).toList(),
      'created_at': createdAt,
      'created_at_human': createdAtHuman,
      'closed_at': closedAt,
    };
  }
}

/// Model lokasi kasus
class CaseLocation {
  final String address;
  final String latitude;
  final String longitude;
  final double? accuracy;
  final String? what3words;

  CaseLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.what3words,
  });

  factory CaseLocation.fromJson(Map<String, dynamic> json) {
    // Safe parsing for accuracy (can be string or number)
    double? parseAccuracy(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return CaseLocation(
      address: json['address']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '0',
      longitude: json['longitude']?.toString() ?? '0',
      accuracy: parseAccuracy(json['accuracy']),
      what3words: json['what3words']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'what3words': what3words,
    };
  }
}

/// Model reporter/pelapor
class CaseReporter {
  final String? name;
  final String phone;
  final String? email;

  CaseReporter({
    this.name,
    required this.phone,
    this.email,
  });

  factory CaseReporter.fromJson(Map<String, dynamic> json) {
    return CaseReporter(
      name: json['name']?.toString(),
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
    };
  }
}

/// Model navigasi ke lokasi
class CaseNavigation {
  final double distanceKm;
  final int estimatedTimeMinutes;
  final String directionsApiUrl;
  final String googleMapsUrl;
  final PetugasLocation petugasLocation;

  CaseNavigation({
    required this.distanceKm,
    required this.estimatedTimeMinutes,
    required this.directionsApiUrl,
    required this.googleMapsUrl,
    required this.petugasLocation,
  });

  factory CaseNavigation.fromJson(Map<String, dynamic> json) {
    // Safe parsing for distance (can be string or number)
    double parseDistance(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CaseNavigation(
      distanceKm: parseDistance(json['distance_km']),
      estimatedTimeMinutes: json['estimated_time_minutes']?.toInt() ?? 0,
      directionsApiUrl: json['directions_api_url']?.toString() ?? '',
      googleMapsUrl: json['google_maps_url']?.toString() ?? '',
      petugasLocation: PetugasLocation.fromJson(json['petugas_location'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance_km': distanceKm,
      'estimated_time_minutes': estimatedTimeMinutes,
      'directions_api_url': directionsApiUrl,
      'google_maps_url': googleMapsUrl,
      'petugas_location': petugasLocation.toJson(),
    };
  }
}

/// Model lokasi petugas
class PetugasLocation {
  final String latitude;
  final String longitude;

  PetugasLocation({
    required this.latitude,
    required this.longitude,
  });

  factory PetugasLocation.fromJson(Map<String, dynamic> json) {
    return PetugasLocation(
      latitude: json['latitude']?.toString() ?? '0',
      longitude: json['longitude']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Model timeline/event kasus
class CaseTimeline {
  final String action;
  final String description;
  final String actor;
  final String createdAt;
  final String createdAtHuman;

  CaseTimeline({
    required this.action,
    required this.description,
    required this.actor,
    required this.createdAt,
    required this.createdAtHuman,
  });

  factory CaseTimeline.fromJson(Map<String, dynamic> json) {
    return CaseTimeline(
      action: json['action']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      actor: json['actor']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      createdAtHuman: json['created_at_human']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'description': description,
      'actor': actor,
      'created_at': createdAt,
      'created_at_human': createdAtHuman,
    };
  }
}

/// Model untuk kasus baru (new assignments)
class NewAssignmentCase {
  final String id;
  final String shortId;
  final String category;
  final String status;
  final CaseLocation location;
  final double? distanceKm;
  final int? etaMinutes;
  final int? priority;
  final String dispatchedAt;
  final String dispatchedAtHuman;

  NewAssignmentCase({
    required this.id,
    required this.shortId,
    required this.category,
    required this.status,
    required this.location,
    this.distanceKm,
    this.etaMinutes,
    this.priority,
    required this.dispatchedAt,
    required this.dispatchedAtHuman,
  });

  factory NewAssignmentCase.fromJson(Map<String, dynamic> json) {
    // Safe parsing for distance (can be string or number)
    double? parseDistance(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return NewAssignmentCase(
      id: json['id']?.toString() ?? '',
      shortId: json['short_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      location: CaseLocation.fromJson(json['location'] ?? {}),
      distanceKm: parseDistance(json['distance_km']),
      etaMinutes: json['eta_minutes']?.toInt(),
      priority: json['priority']?.toInt(),
      dispatchedAt: json['dispatched_at']?.toString() ?? '',
      dispatchedAtHuman: json['dispatched_at_human']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'short_id': shortId,
      'category': category,
      'status': status,
      'location': location.toJson(),
      'distance_km': distanceKm,
      'eta_minutes': etaMinutes,
      'priority': priority,
      'dispatched_at': dispatchedAt,
      'dispatched_at_human': dispatchedAtHuman,
    };
  }
}

/// Model response unread count
class UnreadCount {
  final int unreadCount;
  final bool hasNewAssignments;

  UnreadCount({
    required this.unreadCount,
    required this.hasNewAssignments,
  });

  factory UnreadCount.fromJson(Map<String, dynamic> json) {
    return UnreadCount(
      unreadCount: json['unread_count']?.toInt() ?? 0,
      hasNewAssignments: json['has_new_assignments'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unread_count': unreadCount,
      'has_new_assignments': hasNewAssignments,
    };
  }
}

/// Model response check updates
class CheckUpdatesResponse {
  final bool hasUpdates;
  final List<NewAssignmentCase> newAssignments;
  final List<StatusUpdate> statusUpdates;

  CheckUpdatesResponse({
    required this.hasUpdates,
    required this.newAssignments,
    required this.statusUpdates,
  });

  factory CheckUpdatesResponse.fromJson(Map<String, dynamic> json) {
    return CheckUpdatesResponse(
      hasUpdates: json['has_updates'] ?? false,
      newAssignments: (json['new_assignments'] as List<dynamic>? ?? [])
          .map((item) => NewAssignmentCase.fromJson(item))
          .toList(),
      statusUpdates: (json['status_updates'] as List<dynamic>? ?? [])
          .map((item) => StatusUpdate.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_updates': hasUpdates,
      'new_assignments': newAssignments.map((a) => a.toJson()).toList(),
      'status_updates': statusUpdates.map((s) => s.toJson()).toList(),
    };
  }
}

/// Model status update
class StatusUpdate {
  final String id;
  final String oldStatus;
  final String newStatus;
  final String updatedAt;

  StatusUpdate({
    required this.id,
    required this.oldStatus,
    required this.newStatus,
    required this.updatedAt,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      id: json['id']?.toString() ?? '',
      oldStatus: json['old_status']?.toString() ?? '',
      newStatus: json['new_status']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'old_status': oldStatus,
      'new_status': newStatus,
      'updated_at': updatedAt,
    };
  }
}

/// Model response What3Words
class What3WordsResponse {
  final String words;
  final double latitude;
  final double longitude;

  What3WordsResponse({
    required this.words,
    required this.latitude,
    required this.longitude,
  });

  factory What3WordsResponse.fromJson(Map<String, dynamic> json) {
    // Safe parsing for coordinates (can be string or number)
    double parseCoordinate(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return What3WordsResponse(
      words: json['words']?.toString() ?? '',
      latitude: parseCoordinate(json['latitude']),
      longitude: parseCoordinate(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'words': words,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Model lokasi petugas saat ini
class CurrentLocation {
  final String latitude;
  final String longitude;
  final String lastUpdate;
  final String lastUpdateHuman;

  CurrentLocation({
    required this.latitude,
    required this.longitude,
    required this.lastUpdate,
    required this.lastUpdateHuman,
  });

  factory CurrentLocation.fromJson(Map<String, dynamic> json) {
    return CurrentLocation(
      latitude: json['latitude']?.toString() ?? '0',
      longitude: json['longitude']?.toString() ?? '0',
      lastUpdate: json['last_update']?.toString() ?? '',
      lastUpdateHuman: json['last_update_human']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'last_update': lastUpdate,
      'last_update_human': lastUpdateHuman,
    };
  }
}
