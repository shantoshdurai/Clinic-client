enum PaymentMode {
  cash,
  upi,
  card,
  pending,
}

extension PaymentModeExtension on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI / GPay / PhonePe';
      case PaymentMode.card:
        return 'Card / POS';
      case PaymentMode.pending:
        return 'Pending Collection';
    }
  }
}

enum PaymentStatus {
  paid,
  partial,
  pending,
  waived,
}

extension PaymentStatusExtension on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Settled / Paid';
      case PaymentStatus.partial:
        return 'Partially Paid';
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.waived:
        return 'Fee Waived';
    }
  }
}

class ProcedureCharge {
  final String id;
  final String title;
  final double amount;
  final String addedBy; // 'Doctor' or 'Nurse'
  final DateTime addedAt;

  ProcedureCharge({
    required this.id,
    required this.title,
    required this.amount,
    required this.addedBy,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory ProcedureCharge.fromMap(Map<String, dynamic> map) {
    return ProcedureCharge(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      addedBy: map['addedBy'] ?? 'Doctor',
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Payment {
  final String id;
  final String billNumber;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String branchId;
  final double consultationFee;
  final List<ProcedureCharge> procedureCharges;
  final double totalAmount;
  final double paidToNurse;
  final double paidToDoctor;
  final PaymentMode nursePaymentMode;
  final PaymentMode doctorPaymentMode;
  final double amountPaid;
  final double balance;
  final PaymentStatus status;
  final String collectedByType; // 'Nurse', 'Doctor', 'Split', 'Pending'
  final String collectedByName;
  final DateTime paymentDate;
  final String? notes;

  Payment({
    required this.id,
    required this.billNumber,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    this.patientPhone = '',
    this.branchId = 'main_clinic',
    required this.consultationFee,
    this.procedureCharges = const [],
    double? totalAmount,
    this.paidToNurse = 0.0,
    this.paidToDoctor = 0.0,
    this.nursePaymentMode = PaymentMode.cash,
    this.doctorPaymentMode = PaymentMode.upi,
    double? amountPaid,
    double? balance,
    PaymentStatus? status,
    required this.collectedByType,
    required this.collectedByName,
    required this.paymentDate,
    this.notes,
  })  : totalAmount = totalAmount ??
            (consultationFee +
                (procedureCharges.isEmpty
                    ? 0.0
                    : procedureCharges.fold(0.0, (sum, item) => sum + item.amount))),
        amountPaid = amountPaid ?? (paidToNurse + paidToDoctor),
        balance = balance ??
            (((totalAmount ??
                        (consultationFee +
                            (procedureCharges.isEmpty
                                ? 0.0
                                : procedureCharges.fold(0.0, (sum, item) => sum + item.amount)))) -
                    (amountPaid ?? (paidToNurse + paidToDoctor)))
                .clamp(0.0, 999999.0)),
        status = status ??
            (((amountPaid ?? (paidToNurse + paidToDoctor)) >=
                    (totalAmount ??
                        (consultationFee +
                            (procedureCharges.isEmpty
                                ? 0.0
                                : procedureCharges.fold(0.0, (sum, item) => sum + item.amount)))))
                ? PaymentStatus.paid
                : (((paidToNurse + paidToDoctor) > 0)
                    ? PaymentStatus.partial
                    : PaymentStatus.pending));

  PaymentMode get paymentMode =>
      paidToNurse > 0 ? nursePaymentMode : (paidToDoctor > 0 ? doctorPaymentMode : PaymentMode.cash);

  Payment copyWith({
    String? id,
    String? billNumber,
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? branchId,
    double? consultationFee,
    List<ProcedureCharge>? procedureCharges,
    double? totalAmount,
    double? paidToNurse,
    double? paidToDoctor,
    PaymentMode? nursePaymentMode,
    PaymentMode? doctorPaymentMode,
    double? amountPaid,
    double? balance,
    PaymentStatus? status,
    String? collectedByType,
    String? collectedByName,
    DateTime? paymentDate,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      branchId: branchId ?? this.branchId,
      consultationFee: consultationFee ?? this.consultationFee,
      procedureCharges: procedureCharges ?? this.procedureCharges,
      totalAmount: totalAmount,
      paidToNurse: paidToNurse ?? this.paidToNurse,
      paidToDoctor: paidToDoctor ?? this.paidToDoctor,
      nursePaymentMode: nursePaymentMode ?? this.nursePaymentMode,
      doctorPaymentMode: doctorPaymentMode ?? this.doctorPaymentMode,
      amountPaid: amountPaid,
      balance: balance,
      status: status,
      collectedByType: collectedByType ?? this.collectedByType,
      collectedByName: collectedByName ?? this.collectedByName,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'branchId': branchId,
      'consultationFee': consultationFee,
      'procedureCharges': procedureCharges.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'paidToNurse': paidToNurse,
      'paidToDoctor': paidToDoctor,
      'nursePaymentMode': nursePaymentMode.name,
      'doctorPaymentMode': doctorPaymentMode.name,
      'amountPaid': amountPaid,
      'balance': balance,
      'status': status.name,
      'collectedByType': collectedByType,
      'collectedByName': collectedByName,
      'paymentDate': paymentDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    final procs = (map['procedureCharges'] as List<dynamic>?)
            ?.map((e) => ProcedureCharge.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    return Payment(
      id: map['id'] ?? '',
      billNumber: map['billNumber'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      patientPhone: map['patientPhone'] ?? '',
      branchId: map['branchId'] ?? 'main_clinic',
      consultationFee: (map['consultationFee'] as num?)?.toDouble() ?? 500.0,
      procedureCharges: procs,
      totalAmount: (map['totalAmount'] as num?)?.toDouble(),
      paidToNurse: (map['paidToNurse'] as num?)?.toDouble() ?? 0.0,
      paidToDoctor: (map['paidToDoctor'] as num?)?.toDouble() ?? 0.0,
      nursePaymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == map['nursePaymentMode'],
        orElse: () => PaymentMode.cash,
      ),
      doctorPaymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == map['doctorPaymentMode'],
        orElse: () => PaymentMode.upi,
      ),
      amountPaid: (map['amountPaid'] as num?)?.toDouble(),
      balance: (map['balance'] as num?)?.toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.paid,
      ),
      collectedByType: map['collectedByType'] ?? 'Nurse',
      collectedByName: map['collectedByName'] ?? 'Nurse Desk',
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate']) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes'],
    );
  }
}
