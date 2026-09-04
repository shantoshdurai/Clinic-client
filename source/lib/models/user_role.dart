enum UserRole {
  customer,
  staff,
  doctor,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Patient / Customer';
      case UserRole.staff:
        return 'Staff / OP Reception';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.admin:
        return 'Super Admin';
    }
  }

  String get shortName {
    switch (this) {
      case UserRole.customer:
        return 'Patient';
      case UserRole.staff:
        return 'Staff';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Roles that reach clinical records and money. Used to gate screens.
  bool get isClinicStaff =>
      this == UserRole.staff || this == UserRole.doctor || this == UserRole.admin;

  static UserRole fromName(String? name) {
    return UserRole.values.firstWhere(
      (r) => r.name == name,
      orElse: () => UserRole.customer,
    );
  }
}

class AppUser {
  /// Firebase Auth UID for staff/doctor/admin accounts; the patient document
  /// id for customers.
  final String id;
  final String name;
  final String emailOrPhone;
  final UserRole role;
  final String? patientId; // e.g. P-101
  final String? staffId; // e.g. STF-101
  final String? doctorId; // e.g. doc_raj
  final String? branchId;
  final String? avatarUrl;
  final String? phone;

  /// An admin can disable an account without deleting it. A disabled user is
  /// signed out at the next role check.
  final bool active;

  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.emailOrPhone,
    required this.role,
    this.patientId,
    this.staffId,
    this.doctorId,
    this.branchId,
    this.avatarUrl,
    this.phone,
    this.active = true,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isDoctor => role == UserRole.doctor;
  bool get isStaff => role == UserRole.staff;

  /// Admins get doctor and reception screens too.
  bool get canUseDoctorCabin => role == UserRole.doctor || role == UserRole.admin;
  bool get canUseReception => role == UserRole.staff || role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? name,
    String? emailOrPhone,
    UserRole? role,
    String? patientId,
    String? staffId,
    String? doctorId,
    String? branchId,
    String? avatarUrl,
    String? phone,
    bool? active,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
      role: role ?? this.role,
      patientId: patientId ?? this.patientId,
      staffId: staffId ?? this.staffId,
      doctorId: doctorId ?? this.doctorId,
      branchId: branchId ?? this.branchId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emailOrPhone': emailOrPhone,
        'email': emailOrPhone,
        'role': role.name,
        'patientId': patientId,
        'staffId': staffId,
        'doctorId': doctorId,
        'branchId': branchId,
        'avatarUrl': avatarUrl,
        'phone': phone,
        'active': active,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map, {String? uid}) {
    return AppUser(
      id: uid ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      emailOrPhone:
          map['emailOrPhone'] as String? ?? map['email'] as String? ?? '',
      role: UserRoleExtension.fromName(map['role'] as String?),
      patientId: map['patientId'] as String?,
      staffId: map['staffId'] as String?,
      doctorId: map['doctorId'] as String?,
      branchId: map['branchId'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      phone: map['phone'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
    );
  }
}
