class CaseNote {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String date;
  
  // Public clinical fields (visible to patient)
  final String chiefComplaint;
  final String clinicalFindings;
  final String diagnosis;
  final String treatmentAdvice;
  
  // Private clinical notes (doctor/clinic only)
  final String? privateDoctorNotes;
  final DateTime createdAt;

  CaseNote({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.chiefComplaint,
    required this.clinicalFindings,
    required this.diagnosis,
    required this.treatmentAdvice,
    this.privateDoctorNotes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'appointmentId': appointmentId,
        'patientId': patientId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'date': date,
        'chiefComplaint': chiefComplaint,
        'clinicalFindings': clinicalFindings,
        'diagnosis': diagnosis,
        'treatmentAdvice': treatmentAdvice,
        'privateDoctorNotes': privateDoctorNotes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CaseNote.fromMap(Map<String, dynamic> map) {
    return CaseNote(
      id: map['id'] as String? ?? '',
      appointmentId: map['appointmentId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      doctorId: map['doctorId'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? '',
      date: map['date'] as String? ?? '',
      chiefComplaint: map['chiefComplaint'] as String? ?? '',
      clinicalFindings: map['clinicalFindings'] as String? ?? '',
      diagnosis: map['diagnosis'] as String? ?? '',
      treatmentAdvice: map['treatmentAdvice'] as String? ?? '',
      privateDoctorNotes: map['privateDoctorNotes'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
