/// Editable clinic identity and operating configuration.
///
/// Lives in Firestore at `clinic_settings/main` and is streamed into
/// [ClinicStateProvider], so an edit by the Super Admin reaches every signed-in
/// device without a rebuild or a reinstall.
class ClinicSettings {
  final String clinicName;
  final String tagline;
  final String address;
  final String locality;
  final String phone;
  final String whatsapp;
  final String workingHours;
  final String registrationNumber;
  final String gstNumber;
  final String mapUrl;

  /// Default consultation fee suggested at the OP desk (rupees).
  final double defaultConsultationFee;

  /// Prefix used when minting patient IDs, e.g. `P-` gives `P-101`.
  final String patientIdPrefix;

  /// Number the next patient ID starts from. Advanced on every registration.
  final int patientIdStart;

  /// Prefix used on printed bill numbers.
  final String billPrefix;

  final DateTime? updatedAt;
  final String updatedByName;

  const ClinicSettings({
    required this.clinicName,
    required this.tagline,
    this.address = '',
    this.locality = '',
    this.phone = '',
    this.whatsapp = '',
    this.workingHours = '',
    this.registrationNumber = '',
    this.gstNumber = '',
    this.mapUrl = '',
    this.defaultConsultationFee = 500.0,
    this.patientIdPrefix = 'P-',
    this.patientIdStart = 101,
    this.billPrefix = 'BILL',
    this.updatedAt,
    this.updatedByName = '',
  });

  /// Used before the Firestore document arrives, and as the seed written on
  /// first admin setup.
  static const ClinicSettings fallback = ClinicSettings(
    clinicName: 'AS Clinic',
    tagline: 'General Health & Outpatient Care Centre',
    address: '',
    locality: '',
    phone: '',
    whatsapp: '',
    workingHours: '',
  );

  ClinicSettings copyWith({
    String? clinicName,
    String? tagline,
    String? address,
    String? locality,
    String? phone,
    String? whatsapp,
    String? workingHours,
    String? registrationNumber,
    String? gstNumber,
    String? mapUrl,
    double? defaultConsultationFee,
    String? patientIdPrefix,
    int? patientIdStart,
    String? billPrefix,
    DateTime? updatedAt,
    String? updatedByName,
  }) {
    return ClinicSettings(
      clinicName: clinicName ?? this.clinicName,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
      locality: locality ?? this.locality,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      workingHours: workingHours ?? this.workingHours,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      mapUrl: mapUrl ?? this.mapUrl,
      defaultConsultationFee: defaultConsultationFee ?? this.defaultConsultationFee,
      patientIdPrefix: patientIdPrefix ?? this.patientIdPrefix,
      patientIdStart: patientIdStart ?? this.patientIdStart,
      billPrefix: billPrefix ?? this.billPrefix,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByName: updatedByName ?? this.updatedByName,
    );
  }

  Map<String, dynamic> toMap() => {
        'clinicName': clinicName,
        'tagline': tagline,
        'address': address,
        'locality': locality,
        'phone': phone,
        'whatsapp': whatsapp,
        'workingHours': workingHours,
        'registrationNumber': registrationNumber,
        'gstNumber': gstNumber,
        'mapUrl': mapUrl,
        'defaultConsultationFee': defaultConsultationFee,
        'patientIdPrefix': patientIdPrefix,
        'patientIdStart': patientIdStart,
        'billPrefix': billPrefix,
        'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
        'updatedByName': updatedByName,
      };

  factory ClinicSettings.fromMap(Map<String, dynamic> map) {
    return ClinicSettings(
      clinicName: (map['clinicName'] as String?)?.trim().isNotEmpty == true
          ? map['clinicName'] as String
          : fallback.clinicName,
      tagline: map['tagline'] as String? ?? fallback.tagline,
      address: map['address'] as String? ?? '',
      locality: map['locality'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      whatsapp: map['whatsapp'] as String? ?? '',
      workingHours: map['workingHours'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      gstNumber: map['gstNumber'] as String? ?? '',
      mapUrl: map['mapUrl'] as String? ?? '',
      defaultConsultationFee:
          (map['defaultConsultationFee'] as num?)?.toDouble() ?? 500.0,
      patientIdPrefix: map['patientIdPrefix'] as String? ?? 'P-',
      patientIdStart: (map['patientIdStart'] as num?)?.toInt() ?? 101,
      billPrefix: map['billPrefix'] as String? ?? 'BILL',
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      updatedByName: map['updatedByName'] as String? ?? '',
    );
  }
}
