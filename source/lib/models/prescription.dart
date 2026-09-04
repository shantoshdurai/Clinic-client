class PrescriptionItem {
  final String id;
  final String medicineName;
  final String dosage; // e.g. "500 mg"
  final bool morning;
  final bool afternoon;
  final bool night;
  final String foodTiming; // "After Food" or "Before Food"
  final int durationDays;
  final String? instructions;

  PrescriptionItem({
    required this.id,
    required this.medicineName,
    this.dosage = '500mg',
    this.morning = true,
    this.afternoon = false,
    this.night = true,
    this.foodTiming = 'After Food',
    this.durationDays = 5,
    this.instructions,
  });

  String get dosagePattern {
    return '${morning ? "1" : "0"} - ${afternoon ? "1" : "0"} - ${night ? "1" : "0"}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicineName': medicineName,
        'dosage': dosage,
        'morning': morning,
        'afternoon': afternoon,
        'night': night,
        'foodTiming': foodTiming,
        'durationDays': durationDays,
        'instructions': instructions,
      };

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      id: map['id'] as String? ?? '',
      medicineName: map['medicineName'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      morning: map['morning'] as bool? ?? false,
      afternoon: map['afternoon'] as bool? ?? false,
      night: map['night'] as bool? ?? false,
      foodTiming: map['foodTiming'] as String? ?? 'After Food',
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 5,
      instructions: map['instructions'] as String?,
    );
  }
}

class Prescription {
  final String id;
  final String prescriptionNumber; // e.g. "RX-2026-0817-001"
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String branchId;
  final String date;
  final List<PrescriptionItem> items;
  final String? followUpDate;
  final String? followUpReason;
  final String? doctorNotes;
  final bool isDispensed;
  final DateTime createdAt;

  Prescription({
    required this.id,
    required this.prescriptionNumber,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.branchId,
    required this.date,
    required this.items,
    this.followUpDate,
    this.followUpReason,
    this.doctorNotes,
    this.isDispensed = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'prescriptionNumber': prescriptionNumber,
        'appointmentId': appointmentId,
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'branchId': branchId,
        'date': date,
        'doctorNotes': doctorNotes,
        'followUpDate': followUpDate,
        'followUpReason': followUpReason,
        'isDispensed': isDispensed,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((i) => i.toMap()).toList(),
      };

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] as String? ?? '',
      prescriptionNumber: map['prescriptionNumber'] as String? ?? '',
      appointmentId: map['appointmentId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      patientName: map['patientName'] as String? ?? '',
      doctorId: map['doctorId'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? '',
      branchId: map['branchId'] as String? ?? 'main_clinic',
      date: map['date'] as String? ?? '',
      items: (map['items'] as List?)
              ?.map((i) => PrescriptionItem.fromMap(Map<String, dynamic>.from(i as Map)))
              .toList() ??
          const [],
      followUpDate: map['followUpDate'] as String?,
      followUpReason: map['followUpReason'] as String?,
      doctorNotes: map['doctorNotes'] as String?,
      isDispensed: map['isDispensed'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
