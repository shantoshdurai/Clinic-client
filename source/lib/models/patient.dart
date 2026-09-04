class Patient {
  final String id;
  final String patientId; // e.g. PAT-000123
  final String name;
  final String mobile;
  final String gender; // Male, Female, Other
  final int age;
  final String? dateOfBirth;
  final String address;
  final String bloodGroup;
  final DateTime registeredAt;
  final String? emergencyContact;
  final String? allergies;

  Patient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.mobile,
    required this.gender,
    required this.age,
    this.dateOfBirth,
    required this.address,
    this.bloodGroup = 'O+',
    required this.registeredAt,
    this.emergencyContact,
    this.allergies,
  });

  Patient copyWith({
    String? id,
    String? patientId,
    String? name,
    String? mobile,
    String? gender,
    int? age,
    String? dateOfBirth,
    String? address,
    String? bloodGroup,
    DateTime? registeredAt,
    String? emergencyContact,
    String? allergies,
  }) {
    return Patient(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      registeredAt: registeredAt ?? this.registeredAt,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      allergies: allergies ?? this.allergies,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'name': name,
      'mobile': mobile,
      'gender': gender,
      'age': age,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'bloodGroup': bloodGroup,
      'registeredAt': registeredAt.toIso8601String(),
      'emergencyContact': emergencyContact,
      'allergies': allergies,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      gender: map['gender'] ?? 'Male',
      age: (map['age'] as num?)?.toInt() ?? 30,
      dateOfBirth: map['dateOfBirth'],
      address: map['address'] ?? '',
      bloodGroup: map['bloodGroup'] ?? 'O+',
      registeredAt: map['registeredAt'] != null
          ? DateTime.tryParse(map['registeredAt']) ?? DateTime.now()
          : DateTime.now(),
      emergencyContact: map['emergencyContact'],
      allergies: map['allergies'],
    );
  }
}
