enum BloodType { A, B, AB, O, UNKNOWN }

enum Hubungan {
  KEPALA_KELUARGA,
  ISTRI,
  SUAMI,
  ANAK,
  AYAH,
  IBU,
  KAKEK,
  NENEK,
  CUCU,
  SAUDARA,
  LAINNYA
}

class CitizenProfile {
  final int? id; // Made optional because API might not always return it
  final String userId;
  final String? nik;
  final String? whatsappKeluarga;
  final Hubungan? hubungan;
  final DateTime? birthDate;
  final BloodType? bloodType;
  final String? chronicConditions;
  final String? ktpImageUrl;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  CitizenProfile({
    this.id, // Made optional
    required this.userId,
    this.nik,
    this.whatsappKeluarga,
    this.hubungan,
    this.birthDate,
    this.bloodType,
    this.chronicConditions,
    this.ktpImageUrl,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CitizenProfile.fromJson(Map<String, dynamic> json) {
    print('📋 Parsing CitizenProfile from JSON: $json');
    return CitizenProfile(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: json['user_id']?.toString() ?? '',
      nik: json['nik']?.toString(),
      whatsappKeluarga: json['whatsapp_keluarga']?.toString(),
      hubungan: json['hubungan'] != null
          ? Hubungan.values.firstWhere(
              (e) => e.toString().split('.').last == json['hubungan'],
              orElse: () => Hubungan.LAINNYA,
            )
          : null,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      bloodType: json['blood_type'] != null
          ? BloodType.values.firstWhere(
              (e) => e.toString().split('.').last == json['blood_type'],
              orElse: () => BloodType.UNKNOWN,
            )
          : null,
      chronicConditions: json['chronic_conditions']?.toString(),
      ktpImageUrl: json['ktp_image_url']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
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
      'user_id': userId,
      'nik': nik,
      'whatsapp_keluarga': whatsappKeluarga,
      'hubungan': hubungan?.toString().split('.').last,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'blood_type': bloodType?.toString().split('.').last,
      'chronic_conditions': chronicConditions,
      'ktp_image_url': ktpImageUrl,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
