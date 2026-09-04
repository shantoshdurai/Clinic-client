import 'payment.dart';

class Vitals {
  final String? bp; // e.g. "120/80"
  final double? weightKg; // e.g. 68.5
  final double? heightCm; // e.g. 172.0
  final int? pulseBpm; // e.g. 74
  final double? temperatureF; // e.g. 98.4
  final int? spo2Percent; // e.g. 99
  final int? bloodSugarMgDl; // e.g. 110

  Vitals({
    this.bp,
    this.weightKg,
    this.heightCm,
    this.pulseBpm,
    this.temperatureF,
    this.spo2Percent,
    this.bloodSugarMgDl,
  });

  double? get bmi {
    if (weightKg != null && heightCm != null && heightCm! >= 50 && heightCm! <= 250 && weightKg! > 0) {
      final heightM = heightCm! / 100.0;
      return double.parse((weightKg! / (heightM * heightM)).toStringAsFixed(1));
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'bp': bp,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'pulseBpm': pulseBpm,
      'temperatureF': temperatureF,
      'spo2Percent': spo2Percent,
      'bloodSugarMgDl': bloodSugarMgDl,
    };
  }

  factory Vitals.fromMap(Map<String, dynamic> map) {
    return Vitals(
      bp: map['bp'],
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      pulseBpm: (map['pulseBpm'] as num?)?.toInt(),
      temperatureF: (map['temperatureF'] as num?)?.toDouble(),
      spo2Percent: (map['spo2Percent'] as num?)?.toInt(),
      bloodSugarMgDl: (map['bloodSugarMgDl'] as num?)?.toInt(),
    );
  }
}

class OpVisit {
  final String id;
  final String opNumber; // e.g. "OP-20260819-01"
  final int tokenNumber; // 1, 2, 3...
  final String branchId;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String doctorId;
  final String doctorName;
  final String date;
  final String time;
  final String reasonForVisit;
  final Vitals vitals;
  final String status; // 'waiting', 'in_consultation', 'completed', 'cancelled'
  final double consultationFee;
  final List<ProcedureCharge> procedureCharges;
  final double amountPaid;
  final double balance;
  final PaymentStatus paymentStatus;
  final String collectedByType; // 'Nurse', 'Doctor', 'Split', 'Pending'
  final String? diagnosis;
  final String? clinicalFindings;
  final String? treatmentAdvice;
  final DateTime createdAt;

  OpVisit({
    required this.id,
    required this.opNumber,
    this.tokenNumber = 1,
    this.branchId = 'main_clinic',
    required this.patientId,
    required this.patientName,
    this.patientPhone = '',
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.reasonForVisit,
    required this.vitals,
    this.status = 'waiting',
    this.consultationFee = 500.0,
    this.procedureCharges = const [],
    this.amountPaid = 0.0,
    double? balance,
    this.paymentStatus = PaymentStatus.pending,
    this.collectedByType = 'Pending',
    this.diagnosis,
    this.clinicalFindings,
    this.treatmentAdvice,
    required this.createdAt,
  }) : balance = balance ??
            ((consultationFee +
                    (procedureCharges.isEmpty
                        ? 0.0
                        : procedureCharges.fold(0.0, (s, e) => s + e.amount))) -
                amountPaid)
                .clamp(0.0, 999999.0);

  double get totalBill =>
      consultationFee +
      (procedureCharges.isEmpty
          ? 0.0
          : procedureCharges.fold(0.0, (s, e) => s + e.amount));

  OpVisit copyWith({
    String? id,
    String? opNumber,
    int? tokenNumber,
    String? branchId,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? doctorId,
    String? doctorName,
    String? date,
    String? time,
    String? reasonForVisit,
    Vitals? vitals,
    String? status,
    double? consultationFee,
    List<ProcedureCharge>? procedureCharges,
    double? amountPaid,
    double? balance,
    PaymentStatus? paymentStatus,
    String? collectedByType,
    String? diagnosis,
    String? clinicalFindings,
    String? treatmentAdvice,
    DateTime? createdAt,
  }) {
    return OpVisit(
      id: id ?? this.id,
      opNumber: opNumber ?? this.opNumber,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      branchId: branchId ?? this.branchId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      date: date ?? this.date,
      time: time ?? this.time,
      reasonForVisit: reasonForVisit ?? this.reasonForVisit,
      vitals: vitals ?? this.vitals,
      status: status ?? this.status,
      consultationFee: consultationFee ?? this.consultationFee,
      procedureCharges: procedureCharges ?? this.procedureCharges,
      amountPaid: amountPaid ?? this.amountPaid,
      balance: balance ?? this.balance,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      collectedByType: collectedByType ?? this.collectedByType,
      diagnosis: diagnosis ?? this.diagnosis,
      clinicalFindings: clinicalFindings ?? this.clinicalFindings,
      treatmentAdvice: treatmentAdvice ?? this.treatmentAdvice,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opNumber': opNumber,
      'tokenNumber': tokenNumber,
      'branchId': branchId,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'date': date,
      'time': time,
      'reasonForVisit': reasonForVisit,
      'vitals': vitals.toMap(),
      'status': status,
      'consultationFee': consultationFee,
      'procedureCharges': procedureCharges.map((x) => x.toMap()).toList(),
      'amountPaid': amountPaid,
      'balance': balance,
      'paymentStatus': paymentStatus.name,
      'collectedByType': collectedByType,
      'diagnosis': diagnosis,
      'clinicalFindings': clinicalFindings,
      'treatmentAdvice': treatmentAdvice,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OpVisit.fromMap(Map<String, dynamic> map) {
    final procs = (map['procedureCharges'] as List<dynamic>?)
            ?.map((e) => ProcedureCharge.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    return OpVisit(
      id: map['id'] ?? '',
      opNumber: map['opNumber'] ?? '',
      tokenNumber: (map['tokenNumber'] as num?)?.toInt() ?? 1,
      branchId: map['branchId'] ?? 'main_clinic',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      patientPhone: map['patientPhone'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      reasonForVisit: map['reasonForVisit'] ?? '',
      vitals: map['vitals'] != null
          ? Vitals.fromMap(Map<String, dynamic>.from(map['vitals']))
          : Vitals(),
      status: map['status'] ?? 'waiting',
      consultationFee: (map['consultationFee'] as num?)?.toDouble() ?? 500.0,
      procedureCharges: procs,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      collectedByType: map['collectedByType'] ?? 'Pending',
      diagnosis: map['diagnosis'],
      clinicalFindings: map['clinicalFindings'],
      treatmentAdvice: map['treatmentAdvice'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
