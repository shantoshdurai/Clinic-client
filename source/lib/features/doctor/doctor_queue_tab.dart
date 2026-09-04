import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/appointment.dart';
import '../../../models/op_visit.dart';
import '../../../models/payment.dart';
import '../../../providers/clinic_state_provider.dart';

class DoctorQueueTab extends StatefulWidget {
  const DoctorQueueTab({super.key});

  @override
  State<DoctorQueueTab> createState() => _DoctorQueueTabState();
}

class _DoctorQueueTabState extends State<DoctorQueueTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCompleteVisitSheet(BuildContext context, ClinicStateProvider state, Appointment a, OpVisit? opVisit, Payment? payment) {
    final noteCtrl = TextEditingController();
    final extraProcCtrl = TextEditingController();
    final extraFeeCtrl = TextEditingController();
    bool hasExtra = false;
    bool collectInCabin = false;

    final double alreadyPaid = (payment?.paidToNurse ?? opVisit?.amountPaid) ?? (a.isFeePaid ? a.fee : 0.0);
    final double baseFee = opVisit?.consultationFee ?? a.fee;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final double extraFee = hasExtra ? (double.tryParse(extraFeeCtrl.text.trim()) ?? 0.0) : 0.0;
          final double totalBill = baseFee + extraFee;
          final double due = (totalBill - alreadyPaid).clamp(0.0, 999999.0);

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.secondaryLight, borderRadius: BorderRadius.circular(8)),
                            child: Text('Token #${a.tokenNumber}',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: AppTheme.secondary, fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          Text(a.patientName, style: AppTheme.serifTitle(fontSize: 18)),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Patient & Vitals Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.surfaceMuted, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patient Info: ${a.patientId} • Ph: ${a.patientPhone}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        if (a.reason.isNotEmpty && a.reason != 'General Consultation') ...[
                          const SizedBox(height: 4),
                          Text('Symptoms: ${a.reason}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                        if (opVisit != null) ...[
                          Builder(
                            builder: (_) {
                              final v = opVisit.vitals;
                              final List<String> snips = [];
                              if (v.bp != null && v.bp!.isNotEmpty) snips.add('BP: ${v.bp}');
                              if (v.pulseBpm != null) snips.add('Pulse: ${v.pulseBpm}bpm');
                              if (v.temperatureF != null) snips.add('Temp: ${v.temperatureF}°F');
                              if (v.bloodSugarMgDl != null) snips.add('Sugar: ${v.bloodSugarMgDl}mg/dL');
                              if (v.weightKg != null) snips.add('Wt: ${v.weightKg}kg');
                              if (snips.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text('Vitals: ${snips.join(" • ")}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reception Counter Collection:', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                            Text('₹${alreadyPaid.toInt()} Paid',
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: alreadyPaid > 0 ? AppTheme.success : AppTheme.warning)),
                          ],
                        ),
                        if (due > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.warningLight, borderRadius: BorderRadius.circular(8)),
                            child: Text('Due: ₹${due.toInt()}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.warning)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(8)),
                            child: Text('Fully Settled',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.success)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Optional Doctor Notes / Rx
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Prescription / Advice (Optional)',
                      hintText: 'e.g. Paracetamol 650 SOS, Rest 2 days',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Optional In-Cabin Extra Procedure
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Add Extra In-Cabin Charge (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: const Text('For injection, dressing, or ECG performed in cabin', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                    value: hasExtra,
                    activeColor: AppTheme.secondary,
                    onChanged: (val) => setSheetState(() => hasExtra = val),
                  ),

                  if (hasExtra) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: extraProcCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Procedure / Injection Name',
                              hintText: 'e.g. Injection / Dressing',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: extraFeeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setSheetState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Fee (₹)',
                              hintText: '150',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (due > 0)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Collected Extra ₹${due.toInt()} in Cabin (Doctor UPI/Cash)',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                        value: collectInCabin,
                        activeColor: AppTheme.secondary,
                        onChanged: (val) => setSheetState(() => collectInCabin = val),
                      ),
                  ],
                  const SizedBox(height: 18),

                  // 1-Tap Complete Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 1. Add extra charge if any
                        if (hasExtra && extraFee > 0) {
                          final title = extraProcCtrl.text.trim().isNotEmpty ? extraProcCtrl.text.trim() : 'In-Cabin Procedure';
                          state.addDoctorProcedureCharge(
                            opVisitId: a.id,
                            title: title,
                            amount: extraFee,
                          );
                        }

                        // 2. Doctor collects cabin balance if toggled
                        if (hasExtra && collectInCabin && due > 0) {
                          state.collectPaymentInDoctorCabin(
                            opVisitId: a.id,
                            amount: due,
                            mode: PaymentMode.upi,
                            doctorName: a.doctorName,
                            notes: 'Doctor cabin extra procedure fee collection',
                          );
                        }

                        // 3. Complete visit
                        state.completeConsultation(
                          appointmentId: a.id,
                          patientId: a.patientId,
                          doctorId: a.doctorId,
                          doctorName: a.doctorName,
                          chiefComplaint: a.reason,
                          clinicalFindings: '',
                          diagnosis: 'Consultation Completed',
                          treatmentAdvice: noteCtrl.text.trim(),
                        );

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Completed visit for ${a.patientName} (Token #${a.tokenNumber})'),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      label: const Text('Mark Patient Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteVisit(BuildContext context, ClinicStateProvider state, Appointment a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 24),
            const SizedBox(width: 8),
            Text('Cancel & Delete Token?', style: AppTheme.serifTitle(fontSize: 18)),
          ],
        ),
        content: Text('Delete Token #${a.tokenNumber} for ${a.patientName}? This removes the visit and resets its revenue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          ElevatedButton(
            onPressed: () {
              state.deleteOpVisit(a.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted Token #${a.tokenNumber} (${a.patientName})'),
                  backgroundColor: AppTheme.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete Token', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final waiting = state.appointments.where((a) => a.status != AppointmentStatus.completed).toList();
    final completed = state.appointments.where((a) => a.status == AppointmentStatus.completed).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.secondary,
            indicatorWeight: 3,
            labelColor: AppTheme.secondary,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Waiting (${waiting.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Completed (${completed.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildQueueList(context, waiting, state, false, 'No patients currently waiting in queue.'),
              _buildQueueList(context, completed, state, true, 'No completed patient visits yet today.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQueueList(BuildContext context, List<Appointment> list, ClinicStateProvider state, bool isCompletedTab, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline, size: 44, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(emptyMsg, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13.5)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = list[index];
        final opVisit = state.opVisits.cast<OpVisit?>().firstWhere((v) => v != null && v.id == a.id, orElse: () => null);
        final payment = state.payments.cast<Payment?>().firstWhere((p) => p != null && p.appointmentId == a.id, orElse: () => null);

        final double paid = (payment?.paidToNurse ?? opVisit?.amountPaid) ?? (a.isFeePaid ? a.fee : 0.0);
        final double fee = opVisit?.totalBill ?? a.fee;
        final double due = (fee - paid).clamp(0.0, double.infinity);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Token #, Patient info, Payment badge, Delete button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCompletedTab ? AppTheme.surfaceMuted : AppTheme.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Token #${a.tokenNumber}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        color: isCompletedTab ? AppTheme.textSecondary : AppTheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.patientName,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${a.patientId} • Ph: ${a.patientPhone}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: paid > 0 ? AppTheme.successLight : AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      paid > 0 ? '₹${paid.toInt()} Paid' : 'Due ₹${due.toInt()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: paid > 0 ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
                    tooltip: 'Delete Token',
                    onPressed: () => _confirmDeleteVisit(context, state, a),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vitals Chips (if measured)
              if (opVisit != null) ...[
                Builder(
                  builder: (_) {
                    final v = opVisit.vitals;
                    final List<String> vitalSnippets = [];
                    if (v.bp != null && v.bp!.isNotEmpty) vitalSnippets.add('BP: ${v.bp}');
                    if (v.pulseBpm != null) vitalSnippets.add('Pulse: ${v.pulseBpm}bpm');
                    if (v.temperatureF != null) vitalSnippets.add('Temp: ${v.temperatureF}°F');
                    if (v.bloodSugarMgDl != null) vitalSnippets.add('Sugar: ${v.bloodSugarMgDl}mg/dL');
                    if (v.weightKg != null) vitalSnippets.add('Wt: ${v.weightKg}kg');
                    if (v.bmi != null) vitalSnippets.add('BMI: ${v.bmi}');

                    if (vitalSnippets.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vitalSnippets.join(' • '),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    );
                  },
                ),
              ],

              // Chief Reason / Symptoms
              if (a.reason.isNotEmpty && a.reason != 'General Consultation') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.surfaceMuted, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.sick_outlined, size: 14, color: AppTheme.primaryDark),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Symptoms: ${a.reason}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action button: Complete Visit or View Completed Info
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _showCompleteVisitSheet(context, state, a, opVisit, payment),
                  icon: Icon(
                    isCompletedTab ? Icons.check_circle_outline_rounded : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(
                    isCompletedTab ? 'View Consultation Details' : 'Complete Patient Visit',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompletedTab ? AppTheme.textSecondary : AppTheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
