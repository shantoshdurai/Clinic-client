class CashHandover {
  final String id;
  final String date; // 'yyyy-MM-dd'
  final double nurseCash;
  final double nurseUpi;
  final double doctorUpi;
  final double totalRevenue;
  final String handedOverByName;
  final String receivedByName;
  final DateTime settledAt;
  final String status; // 'pending', 'handed_over', 'received'
  final String? notes;

  CashHandover({
    required this.id,
    required this.date,
    required this.nurseCash,
    required this.nurseUpi,
    required this.doctorUpi,
    required this.totalRevenue,
    required this.handedOverByName,
    required this.receivedByName,
    required this.settledAt,
    this.status = 'received',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'nurseCash': nurseCash,
      'nurseUpi': nurseUpi,
      'doctorUpi': doctorUpi,
      'totalRevenue': totalRevenue,
      'handedOverByName': handedOverByName,
      'receivedByName': receivedByName,
      'settledAt': settledAt.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory CashHandover.fromMap(Map<String, dynamic> map) {
    return CashHandover(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      nurseCash: (map['nurseCash'] as num?)?.toDouble() ?? 0.0,
      nurseUpi: (map['nurseUpi'] as num?)?.toDouble() ?? 0.0,
      doctorUpi: (map['doctorUpi'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      handedOverByName: map['handedOverByName'] ?? 'Reception Desk',
      receivedByName: map['receivedByName'] ?? 'Doctor',
      settledAt: map['settledAt'] != null
          ? DateTime.tryParse(map['settledAt']) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] ?? 'received',
      notes: map['notes'],
    );
  }
}
