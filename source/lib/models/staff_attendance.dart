enum AttendanceStatus {
  present,
  absent,
  leave,
}

class StaffAttendance {
  final String id;
  final String staffId;
  final String staffName;
  final String branchId;
  final String date; // YYYY-MM-DD
  final String? checkInTime; // e.g. "08:45 AM"
  final String? checkOutTime; // e.g. "05:30 PM"
  final AttendanceStatus status;
  final String? notes;

  StaffAttendance({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.branchId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.notes,
  });

  StaffAttendance copyWith({
    String? id,
    String? staffId,
    String? staffName,
    String? branchId,
    String? date,
    String? checkInTime,
    String? checkOutTime,
    AttendanceStatus? status,
    String? notes,
  }) {
    return StaffAttendance(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      branchId: branchId ?? this.branchId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'staffId': staffId,
        'staffName': staffName,
        'branchId': branchId,
        'date': date,
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'status': status.name,
        'notes': notes,
      };

  factory StaffAttendance.fromMap(Map<String, dynamic> map) {
    return StaffAttendance(
      id: map['id'] as String? ?? '',
      staffId: map['staffId'] as String? ?? '',
      staffName: map['staffName'] as String? ?? '',
      branchId: map['branchId'] as String? ?? 'main_clinic',
      date: map['date'] as String? ?? '',
      checkInTime: map['checkInTime'] as String?,
      checkOutTime: map['checkOutTime'] as String?,
      status: AttendanceStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'present'),
        orElse: () => AttendanceStatus.present,
      ),
      notes: map['notes'] as String?,
    );
  }
}
