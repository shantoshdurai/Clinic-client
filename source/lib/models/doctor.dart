class DoctorScheduleSlot {
  final String dayOfWeek; // e.g. Monday, Wednesday, Friday
  final String branchId;
  final String startTime; // e.g. "09:00 AM"
  final String endTime; // e.g. "01:00 PM"
  final int slotDurationMinutes; // 15
  final int maxAppointments;

  const DoctorScheduleSlot({
    required this.dayOfWeek,
    required this.branchId,
    required this.startTime,
    required this.endTime,
    this.slotDurationMinutes = 15,
    this.maxAppointments = 20,
  });

  Map<String, dynamic> toMap() => {
        'dayOfWeek': dayOfWeek,
        'branchId': branchId,
        'startTime': startTime,
        'endTime': endTime,
        'slotDurationMinutes': slotDurationMinutes,
        'maxAppointments': maxAppointments,
      };

  factory DoctorScheduleSlot.fromMap(Map<String, dynamic> map) {
    return DoctorScheduleSlot(
      dayOfWeek: map['dayOfWeek'] as String? ?? '',
      branchId: map['branchId'] as String? ?? 'main_clinic',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      slotDurationMinutes: (map['slotDurationMinutes'] as num?)?.toInt() ?? 15,
      maxAppointments: (map['maxAppointments'] as num?)?.toInt() ?? 20,
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String qualification;
  final String specialty;
  final String experienceYears;
  final double consultationFee;
  final String phone;
  final List<String> availableBranchIds;
  final List<DoctorScheduleSlot> schedules;
  final String photoUrl;
  final double rating;
  final int reviewsCount;

  /// Hidden from the OP desk and the patient app when false, without deleting
  /// the historical records that reference this doctor.
  final bool active;

  const Doctor({
    required this.id,
    required this.name,
    required this.qualification,
    required this.specialty,
    required this.experienceYears,
    required this.consultationFee,
    required this.phone,
    required this.availableBranchIds,
    required this.schedules,
    required this.photoUrl,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.active = true,
  });

  /// Name as it should appear on tokens, bills and prescriptions —
  /// "Dr. Raj Saravanan, MD" rather than the bare name.
  String get displayName {
    final degree = qualification.split(',').first.trim();
    if (degree.isEmpty) return name;
    if (name.toLowerCase().contains(degree.toLowerCase())) return name;
    return '$name, $degree';
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? qualification,
    String? specialty,
    String? experienceYears,
    double? consultationFee,
    String? phone,
    List<String>? availableBranchIds,
    List<DoctorScheduleSlot>? schedules,
    String? photoUrl,
    double? rating,
    int? reviewsCount,
    bool? active,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      qualification: qualification ?? this.qualification,
      specialty: specialty ?? this.specialty,
      experienceYears: experienceYears ?? this.experienceYears,
      consultationFee: consultationFee ?? this.consultationFee,
      phone: phone ?? this.phone,
      availableBranchIds: availableBranchIds ?? this.availableBranchIds,
      schedules: schedules ?? this.schedules,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'qualification': qualification,
        'specialty': specialty,
        'experienceYears': experienceYears,
        'consultationFee': consultationFee,
        'phone': phone,
        'availableBranchIds': availableBranchIds,
        'schedules': schedules.map((s) => s.toMap()).toList(),
        'photoUrl': photoUrl,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'active': active,
      };

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      qualification: map['qualification'] as String? ?? '',
      specialty: map['specialty'] as String? ?? 'General Physician',
      experienceYears: map['experienceYears'] as String? ?? '',
      consultationFee: (map['consultationFee'] as num?)?.toDouble() ?? 500.0,
      phone: map['phone'] as String? ?? '',
      availableBranchIds:
          (map['availableBranchIds'] as List?)?.cast<String>() ?? const ['main_clinic'],
      schedules: (map['schedules'] as List?)
              ?.map((s) => DoctorScheduleSlot.fromMap(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          const [],
      photoUrl: map['photoUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 0,
      active: map['active'] as bool? ?? true,
    );
  }
}
