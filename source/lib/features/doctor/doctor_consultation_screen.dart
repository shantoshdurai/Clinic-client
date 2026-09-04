import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/appointment.dart';
import '../../../models/op_visit.dart';
import '../../../models/payment.dart';
import '../../../models/prescription.dart';
import '../../../providers/clinic_state_provider.dart';

class DoctorConsultationScreen extends StatefulWidget {
  final Appointment appointment;

  const DoctorConsultationScreen({super.key, required this.appointment});

  @override
  State<DoctorConsultationScreen> createState() => _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  late TextEditingController _chiefComplaintController;
  final TextEditingController _clinicalFindingsController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _treatmentAdviceController = TextEditingController();

  final List<PrescriptionItem> _prescriptionItems = [];

  bool _needsFollowUp = false;
  String _followUpDate = '';
  final TextEditingController _followUpReasonController = TextEditingController();

  // In-Cabin Extra Procedures (Injection, Dressing, ECG, Sugar test)
  bool _hasExtraProcedure = false;
  final TextEditingController _procedureNameController = TextEditingController(text: 'Injection / Procedure');
  final TextEditingController _procedureFeeController = TextEditingController(text: '150');

  // Doctor Cabin direct fee collection
  bool _collectDoctorFeeInCabin = false;
  PaymentMode _doctorPaymentMode = PaymentMode.upi;

  @override
  void initState() {
    super.initState();
    _chiefComplaintController = TextEditingController(text: widget.appointment.reason);
  }

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _clinicalFindingsController.dispose();
    _diagnosisController.dispose();
    _treatmentAdviceController.dispose();
    _followUpReasonController.dispose();
    _procedureNameController.dispose();
    _procedureFeeController.dispose();
    super.dispose();
  }

  void _showAddMedicineDialog(BuildContext context, ClinicStateProvider state) {
    final medNameCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    bool morning = true;
    bool noon = false;
    bool night = true;
    String food = 'After Food';
    int duration = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Prescription Medicine', style: AppTheme.serifTitle(fontSize: 18)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: medNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name & Dosage *',
                    hintText: 'e.g. Paracetamol 650mg / Dolo 650',
                    prefixIcon: const Icon(Icons.medication_outlined),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.primary),
                      tooltip: 'Quick Suggestions',
                      onSelected: (val) => setDlg(() => medNameCtrl.text = val),
                      itemBuilder: (ctx) => [
                        'Paracetamol 650mg (Dolo 650)',
                        'Pan 40 Tablet (Pantoprazole)',
                        'Amoxicillin 500mg',
                        'Cetirizine 10mg',
                        'Azithromycin 500mg',
                        'ORS Sachet',
                      ].map((m) => PopupMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Dosage Schedule (Morning - Noon - Night):',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Morning (1)'),
                      selected: morning,
                      selectedColor: AppTheme.primaryLight,
                      onSelected: (v) => setDlg(() => morning = v),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Noon (1)'),
                      selected: noon,
                      selectedColor: AppTheme.primaryLight,
                      onSelected: (v) => setDlg(() => noon = v),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Night (1)'),
                      selected: night,
                      selectedColor: AppTheme.primaryLight,
                      onSelected: (v) => setDlg(() => night = v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: food,
                        decoration: const InputDecoration(labelText: 'Timing'),
                        items: const [
                          DropdownMenuItem(value: 'After Food', child: Text('After Food')),
                          DropdownMenuItem(value: 'Before Food', child: Text('Before Food')),
                          DropdownMenuItem(value: 'With Food', child: Text('With Food')),
                          DropdownMenuItem(value: 'Bedtime', child: Text('Bedtime')),
                        ],
                        onChanged: (v) => setDlg(() => food = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: duration,
                        decoration: const InputDecoration(labelText: 'Days'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 Day (SOS)')),
                          DropdownMenuItem(value: 3, child: Text('3 Days')),
                          DropdownMenuItem(value: 5, child: Text('5 Days')),
                          DropdownMenuItem(value: 7, child: Text('7 Days')),
                          DropdownMenuItem(value: 10, child: Text('10 Days')),
                          DropdownMenuItem(value: 14, child: Text('14 Days')),
                          DropdownMenuItem(value: 30, child: Text('30 Days')),
                        ],
                        onChanged: (v) => setDlg(() => duration = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: instructionsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Special Instruction (Optional)',
                    hintText: 'e.g. SOS for fever / 30 mins before food',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = medNameCtrl.text.trim();
                      if (name.isEmpty) return;

                      setState(() {
                        _prescriptionItems.add(PrescriptionItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          medicineName: name,
                          dosage: name.contains('mg') ? name : '1 Tab',
                          morning: morning,
                          afternoon: noon,
                          night: night,
                          foodTiming: food,
                          durationDays: duration,
                          instructions: instructionsCtrl.text.trim(),
                        ));
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    child: const Text('Add to Prescription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final opVisit = state.opVisits.cast<OpVisit?>().firstWhere(
          (v) => v != null && v.id == widget.appointment.id,
          orElse: () => null,
        );

    final payment = state.payments.cast<Payment?>().firstWhere(
          (p) => p != null && p.appointmentId == widget.appointment.id,
          orElse: () => null,
        );

    final double baseConsultation = opVisit?.consultationFee ?? widget.appointment.fee;
    final double extraCharge = _hasExtraProcedure
        ? (double.tryParse(_procedureFeeController.text.trim()) ?? 0.0)
        : 0.0;
    final double totalBill = baseConsultation + extraCharge;
    final double alreadyPaidNurse = (payment?.paidToNurse ?? opVisit?.amountPaid) ?? (widget.appointment.isFeePaid ? widget.appointment.fee : 0.0);
    final double balance = (totalBill - alreadyPaidNurse).clamp(0.0, 99999.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Doctor Consultation', style: AppTheme.serifTitle(fontSize: 20)),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info & Measured Vitals Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Token #${widget.appointment.tokenNumber}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.appointment.patientName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: alreadyPaidNurse > 0 ? AppTheme.successLight : AppTheme.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          alreadyPaidNurse > 0 ? 'Nurse Collected ₹${alreadyPaidNurse.toInt()}' : 'Counter Unpaid',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: alreadyPaidNurse > 0 ? AppTheme.success : AppTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Measured Vitals
                  if (opVisit != null) ...[
                    Builder(
                      builder: (_) {
                        final v = opVisit.vitals;
                        final List<String> snippets = [];
                        if (v.bp != null && v.bp!.isNotEmpty) snippets.add('BP: ${v.bp}');
                        if (v.pulseBpm != null) snippets.add('Pulse: ${v.pulseBpm} bpm');
                        if (v.temperatureF != null) snippets.add('Temp: ${v.temperatureF}°F');
                        if (v.spo2Percent != null) snippets.add('SpO2: ${v.spo2Percent}%');
                        if (v.bloodSugarMgDl != null) snippets.add('Sugar: ${v.bloodSugarMgDl} mg/dL');
                        if (v.weightKg != null) snippets.add('Wt: ${v.weightKg}kg');
                        if (v.bmi != null) snippets.add('BMI: ${v.bmi}');

                        if (snippets.isEmpty) {
                          return const Text('No vitals recorded at reception desk.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic));
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            snippets.join(' • '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Clinical Examination & Diagnosis (Starts Empty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clinical Examination & Diagnosis', style: AppTheme.serifSubtitle(fontSize: 18)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _chiefComplaintController,
                    decoration: const InputDecoration(
                      labelText: 'Chief Complaint / Symptoms',
                      hintText: 'e.g. Fever for 2 days, throat pain',
                      prefixIcon: Icon(Icons.sick_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Primary Diagnosis *',
                      hintText: 'e.g. Acute Viral Pharyngitis / Gastritis',
                      prefixIcon: Icon(Icons.coronavirus_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clinicalFindingsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Examination Notes (Optional)',
                      hintText: 'e.g. Throat congested, lungs clear, vitals normal',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _treatmentAdviceController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Treatment Advice & Guidance (Optional)',
                      hintText: 'e.g. Warm water gargle, rest, drink plenty of fluids',
                      prefixIcon: Icon(Icons.health_and_safety_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Prescription Medicines (Starts Empty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Prescription Medicines (${_prescriptionItems.length})', style: AppTheme.serifSubtitle(fontSize: 18)),
                      TextButton.icon(
                        onPressed: () => _showAddMedicineDialog(context, state),
                        icon: const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.primary),
                        label: Text('Add Medicine',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_prescriptionItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No medicines added yet. Tap "+ Add Medicine" to prescribe tablets/syrups.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textMuted),
                      ),
                    )
                  else
                    ..._prescriptionItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.medicineName,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: AppTheme.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Dosage: ${item.dosagePattern} • ${item.foodTiming} • ${item.durationDays} Days',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  if (item.instructions != null && item.instructions!.isNotEmpty)
                                    Text(
                                      'Note: ${item.instructions}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.danger, size: 20),
                              onPressed: () => setState(() => _prescriptionItems.removeAt(index)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // In-Cabin Extra Procedures (Optional, Doctor types charge)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _hasExtraProcedure ? AppTheme.secondary : AppTheme.border,
                    width: _hasExtraProcedure ? 1.5 : 1),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('In-Cabin Procedures & Additional Fee',
                      style: AppTheme.serifSubtitle(fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                    'Add charges for injections, dressings, or tests done in the doctor cabin.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 10),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Add In-Cabin Procedure Charge',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: Text(
                      _hasExtraProcedure
                          ? 'Extra procedure added (+₹${_procedureFeeController.text})'
                          : 'No extra procedure performed',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                    value: _hasExtraProcedure,
                    activeThumbColor: AppTheme.secondary,
                    onChanged: (val) => setState(() => _hasExtraProcedure = val),
                  ),

                  if (_hasExtraProcedure) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _procedureNameController,
                            decoration: const InputDecoration(
                              labelText: 'Procedure / Injection Name',
                              hintText: 'e.g. Paracetamol IV / Dressing',
                              prefixIcon: Icon(Icons.medical_information_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _procedureFeeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Charge (₹)',
                              hintText: '150',
                              prefixIcon: Icon(Icons.price_check_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Fee Breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Consultation Fee:',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
                            Text('₹${baseConsultation.toInt()}',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        if (_hasExtraProcedure) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Extra (${_procedureNameController.text}):',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, color: AppTheme.secondary)),
                              Text('+ ₹${(double.tryParse(_procedureFeeController.text.trim()) ?? 0.0).toInt()}',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                            ],
                          ),
                        ],
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Bill:',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800, fontSize: 13)),
                            Text('₹${totalBill.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                    color: AppTheme.primaryDark)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Already Paid to Reception:',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12, color: AppTheme.success)),
                            Text('- ₹${alreadyPaidNurse.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700, color: AppTheme.success)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Balance Due:',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: balance > 0 ? AppTheme.danger : AppTheme.success)),
                            Text('₹${balance.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: balance > 0 ? AppTheme.danger : AppTheme.success)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (balance > 0) ...[
                    const SizedBox(height: 14),
                    Text('How is balance ₹${balance.toInt()} being settled?',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _collectDoctorFeeInCabin = false),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: !_collectDoctorFeeInCabin
                                    ? AppTheme.primaryLight
                                    : AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: !_collectDoctorFeeInCabin
                                        ? AppTheme.primary
                                        : AppTheme.border),
                              ),
                              child: Text(
                                'Send to Reception Desk',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: !_collectDoctorFeeInCabin
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: !_collectDoctorFeeInCabin
                                        ? AppTheme.primaryDark
                                        : AppTheme.textPrimary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _collectDoctorFeeInCabin = true),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _collectDoctorFeeInCabin
                                    ? AppTheme.secondaryLight
                                    : AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: _collectDoctorFeeInCabin
                                        ? AppTheme.secondary
                                        : AppTheme.border),
                              ),
                              child: Text(
                                'Collect in Cabin (Doctor UPI/Cash)',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: _collectDoctorFeeInCabin
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: _collectDoctorFeeInCabin
                                        ? AppTheme.secondary
                                        : AppTheme.textPrimary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save and Complete Consultation Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  final diagnosis = _diagnosisController.text.trim();
                  if (diagnosis.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter primary diagnosis before completing consultation'),
                        backgroundColor: AppTheme.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // 1. Add in-cabin procedure if any
                  if (_hasExtraProcedure) {
                    final procName = _procedureNameController.text.trim().isNotEmpty
                        ? _procedureNameController.text.trim()
                        : 'In-Cabin Procedure';
                    final procFee = double.tryParse(_procedureFeeController.text.trim()) ?? 0.0;
                    if (procFee > 0) {
                      state.addDoctorProcedureCharge(
                        opVisitId: widget.appointment.id,
                        title: procName,
                        amount: procFee,
                      );
                    }
                  }

                  // 2. Handle doctor cabin balance collection
                  if (balance > 0 && _collectDoctorFeeInCabin) {
                    state.collectPaymentInDoctorCabin(
                      opVisitId: widget.appointment.id,
                      amount: balance,
                      mode: _doctorPaymentMode,
                      doctorName: widget.appointment.doctorName,
                      notes: 'Doctor cabin direct balance collection',
                    );
                  }

                  // 3. Complete consultation with Rx and Case notes
                  state.completeConsultation(
                    appointmentId: widget.appointment.id,
                    patientId: widget.appointment.patientId,
                    doctorId: widget.appointment.doctorId,
                    doctorName: widget.appointment.doctorName,
                    chiefComplaint: _chiefComplaintController.text.trim(),
                    clinicalFindings: _clinicalFindingsController.text.trim(),
                    diagnosis: diagnosis,
                    treatmentAdvice: _treatmentAdviceController.text.trim(),
                    prescriptionItems: _prescriptionItems,
                    followUpDate: _needsFollowUp ? _followUpDate : null,
                    followUpReason: _needsFollowUp ? _followUpReasonController.text.trim() : null,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Consultation completed for ${widget.appointment.patientName}'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Complete Consultation & Save Rx',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
