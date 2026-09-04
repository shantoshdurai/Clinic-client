enum AppointmentStatus {
  requested,
  confirmed,
  checkedIn,
  inConsultation,
  completed,
  cancelled,
  rescheduled,
  noShow,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.requested:
        return 'Requested';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.checkedIn:
        return 'Checked In';
      case AppointmentStatus.inConsultation:
        return 'In Consultation';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}

class Appointment {
  final String id;
  final String branchId;
  final String patientId; // PAT-000123
  final String patientName;
  final String patientPhone;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String date; // YYYY-MM-DD or readable string
  final String timeSlot; // e.g. "10:30 AM"
  final String reason;
  final AppointmentStatus status;
  final int tokenNumber;
  final String createdByType; // customer, staff, doctor
  final DateTime createdAt;
  final double fee;
  final bool isFeePaid;

  Appointment({
    required this.id,
    required this.branchId,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.date,
    required this.timeSlot,
    required this.reason,
    required this.status,
    required this.tokenNumber,
    required this.createdByType,
    required this.createdAt,
    this.fee = 500.0,
    this.isFeePaid = false,
  });

  Appointment copyWith({
    String? id,
    String? branchId,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? date,
    String? timeSlot,
    String? reason,
    AppointmentStatus? status,
    int? tokenNumber,
    String? createdByType,
    DateTime? createdAt,
    double? fee,
    bool? isFeePaid,
  }) {
    return Appointment(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      createdByType: createdByType ?? this.createdByType,
      createdAt: createdAt ?? this.createdAt,
      fee: fee ?? this.fee,
      isFeePaid: isFeePaid ?? this.isFeePaid,
    );
  }
}
