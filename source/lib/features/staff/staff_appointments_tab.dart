import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/appointment.dart';
import '../../../models/payment.dart';
import '../../../providers/clinic_state_provider.dart';

class StaffAppointmentsTab extends StatefulWidget {
  const StaffAppointmentsTab({super.key});

  @override
  State<StaffAppointmentsTab> createState() => _StaffAppointmentsTabState();
}

class _StaffAppointmentsTabState extends State<StaffAppointmentsTab> {
  String _selectedFilter = 'All';

  void _showRecordVitalsDialog(BuildContext context, Appointment appt, ClinicStateProvider state) {
    final bpController = TextEditingController(text: '120/80');
    final pulseController = TextEditingController(text: '76');
    final tempController = TextEditingController(text: '98.6');
    final weightController = TextEditingController(text: '68.0');
    final heightController = TextEditingController(text: '170.0');
    final sugarController = TextEditingController(text: '110');
    final spo2Controller = TextEditingController(text: '99');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pre-Consultation Vitals', style: AppTheme.serifTitle(fontSize: 22)),
                      Text('${appt.patientName} • Token #${appt.tokenNumber}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                ],
              ),
              const SizedBox(height: 16),

              Text('Record counter vitals before sending patient to doctor cabin:', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textMuted)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bpController,
                      decoration: const InputDecoration(labelText: 'Blood Pressure (BP)', hintText: '120/80 mmHg', prefixIcon: Icon(Icons.favorite_outline)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: pulseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pulse (bpm)', hintText: '76', prefixIcon: Icon(Icons.monitor_heart_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tempController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Temperature (°F)', hintText: '98.6', prefixIcon: Icon(Icons.thermostat_outlined)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: spo2Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'SpO2 Oxygen (%)', hintText: '99', prefixIcon: Icon(Icons.air_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Weight (kg)', hintText: '68.0', prefixIcon: Icon(Icons.scale_outlined)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Height (cm)', hintText: '170.0', prefixIcon: Icon(Icons.height_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: sugarController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Random Blood Sugar (Optional)', hintText: '110 mg/dL', prefixIcon: Icon(Icons.water_drop_outlined)),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    state.recordPatientVitals(
                      appointmentId: appt.id,
                      patientId: appt.patientId,
                      patientName: appt.patientName,
                      doctorId: appt.doctorId,
                      doctorName: appt.doctorName,
                      bp: bpController.text.trim(),
                      pulse: int.tryParse(pulseController.text.trim()) ?? 76,
                      temp: double.tryParse(tempController.text.trim()) ?? 98.6,
                      weight: double.tryParse(weightController.text.trim()) ?? 68.0,
                      height: double.tryParse(heightController.text.trim()) ?? 170.0,
                      spo2: int.tryParse(spo2Controller.text.trim()) ?? 99,
                      bloodSugar: int.tryParse(sugarController.text.trim()),
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Vitals recorded for ${appt.patientName}. Patient queued for Dr. Raj.'),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Save Vitals & Queue for Doctor', style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCollectFeeDialog(BuildContext context, Appointment appt, ClinicStateProvider state) {
    PaymentMode selectedMode = PaymentMode.upi;
    final feeController = TextEditingController(text: '${appt.fee.toInt()}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Collect Consultation Fee', style: AppTheme.serifTitle(fontSize: 20)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appt.patientName, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        Text('${appt.patientId} • Token #${appt.tokenNumber}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    Text('₹${appt.fee.toInt()}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Payment Method', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() => selectedMode = PaymentMode.upi),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedMode == PaymentMode.upi ? AppTheme.primaryLight : AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedMode == PaymentMode.upi ? AppTheme.primary : AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, color: selectedMode == PaymentMode.upi ? AppTheme.primaryDark : AppTheme.textMuted, size: 20),
                            const SizedBox(height: 4),
                            Text('GPay / UPI', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: selectedMode == PaymentMode.upi ? AppTheme.primaryDark : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() => selectedMode = PaymentMode.cash),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedMode == PaymentMode.cash ? AppTheme.primaryLight : AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedMode == PaymentMode.cash ? AppTheme.primary : AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.payments_outlined, color: selectedMode == PaymentMode.cash ? AppTheme.primaryDark : AppTheme.textMuted, size: 20),
                            const SizedBox(height: 4),
                            Text('Cash', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: selectedMode == PaymentMode.cash ? AppTheme.primaryDark : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() => selectedMode = PaymentMode.card),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedMode == PaymentMode.card ? AppTheme.primaryLight : AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedMode == PaymentMode.card ? AppTheme.primary : AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.credit_card_rounded, color: selectedMode == PaymentMode.card ? AppTheme.primaryDark : AppTheme.textMuted, size: 20),
                            const SizedBox(height: 4),
                            Text('Card / POS', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: selectedMode == PaymentMode.card ? AppTheme.primaryDark : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(feeController.text) ?? appt.fee;
                    state.recordStaffPayment(
                      appointmentId: appt.id,
                      patientId: appt.patientId,
                      patientName: appt.patientName,
                      consultationFee: appt.fee,
                      amountPaid: amount,
                      paymentMode: selectedMode,
                      notes: 'Initial consultation fee collected at desk.',
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('₹${amount.toInt()} fee recorded via ${selectedMode.name.toUpperCase()} for ${appt.patientName}'),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Confirm ₹${appt.fee.toInt()} Paid', style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWalkinBookingDialog(BuildContext context, ClinicStateProvider state) {
    String selectedPatientId = state.patients.first.patientId;
    String selectedDoctorId = state.doctors.first.id;
    String selectedSlot = '11:00 AM';
    final reasonController = TextEditingController(text: 'Walk-in General consultation');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Walk-in to Queue', style: AppTheme.serifTitle(fontSize: 20)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedPatientId,
                decoration: const InputDecoration(labelText: 'Select Registered Patient'),
                items: state.patients.map((p) => DropdownMenuItem(value: p.patientId, child: Text('${p.name} (${p.patientId})'))).toList(),
                onChanged: (v) => setDialogState(() => selectedPatientId = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedDoctorId,
                decoration: const InputDecoration(labelText: 'Consulting Doctor'),
                items: state.doctors.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                onChanged: (v) => setDialogState(() => selectedDoctorId = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Chief Complaint / Reason'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final patient = state.patients.firstWhere((p) => p.patientId == selectedPatientId);
                    final doctor = state.doctors.firstWhere((d) => d.id == selectedDoctorId);

                    final appt = state.bookAppointment(
                      patientId: patient.patientId,
                      patientName: patient.name,
                      patientPhone: patient.mobile,
                      doctorId: doctor.id,
                      doctorName: doctor.name,
                      doctorSpecialty: doctor.specialty,
                      date: '18 Aug 2026',
                      timeSlot: selectedSlot,
                      reason: reasonController.text,
                      createdByType: 'staff',
                      fee: doctor.consultationFee,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to Queue: ${patient.name} (Token #${appt.tokenNumber})'),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Add Patient to Live Queue', style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final appointments = state.branchAppointments;

    // Real-Time Daily Reception Tracker Metrics
    final totalToday = appointments.length;
    final toCallRemind = appointments.where((a) => a.status == AppointmentStatus.requested).length;
    final waitingCounter = appointments.where((a) => a.status == AppointmentStatus.checkedIn || a.status == AppointmentStatus.confirmed).length;
    final completed = appointments.where((a) => a.status == AppointmentStatus.completed).length;

    List<Appointment> filteredList = appointments;
    if (_selectedFilter == 'To Call') {
      filteredList = appointments.where((a) => a.status == AppointmentStatus.requested).toList();
    } else if (_selectedFilter == 'Waiting') {
      filteredList = appointments.where((a) => a.status == AppointmentStatus.checkedIn || a.status == AppointmentStatus.confirmed).toList();
    } else if (_selectedFilter == 'Completed') {
      filteredList = appointments.where((a) => a.status == AppointmentStatus.completed).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Spacious Duty Tracker Dashboard
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today\'s Patient Tracker', style: AppTheme.serifTitle(fontSize: 22)),
                          Text('Duty In-Charge: ${state.currentUser?.name ?? 'Reception Desk'}', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showWalkinBookingDialog(context, state),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.glowGreenShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Walk-In',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4 Spacious Metric Cards
                  Row(
                    children: [
                      Expanded(child: _buildMetricBox('Enrolled Today', '$totalToday', AppTheme.primary, Icons.group_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricBox('To Call / Remind', '$toCallRemind', const Color(0xFFD97706), Icons.phone_callback_outlined)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildMetricBox('Waiting in Clinic', '$waitingCounter', const Color(0xFF0284C7), Icons.hourglass_empty_rounded)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricBox('With Doctor / Done', '$completed', AppTheme.accentGreen, Icons.task_alt_rounded)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. Filter Pills Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', appointments.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('To Call', toCallRemind),
                    const SizedBox(width: 8),
                    _buildFilterChip('Waiting', waitingCounter),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', completed),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // 3. Spacious Appointment Cards List
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: filteredList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(Icons.inbox_outlined, size: 40, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            Text('No patient records in this category.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final a = filteredList[index];
                        return _buildSpaciousAppointmentCard(context, a, state);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: color),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, int count) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textPrimary : AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          '$filter ($count)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSpaciousAppointmentCard(BuildContext context, Appointment appt, ClinicStateProvider state) {
    final hasOp = state.opVisits.any((v) => v.patientId == appt.patientId);

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Token + Name + Fee status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Token #${appt.tokenNumber}',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.primaryDark, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.patientName,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '${appt.patientId} • Ph: ${appt.patientPhone}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: appt.isFeePaid ? AppTheme.primaryLight : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appt.isFeePaid ? '₹${appt.fee.toInt()} Paid' : 'Fee Pending',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: appt.isFeePaid ? AppTheme.primaryDark : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Slot Details & Doctor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 15, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${appt.date} • ${appt.timeSlot}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                Text(
                  appt.doctorName.startsWith('Dr.') ? appt.doctorName : 'Dr. ${appt.doctorName}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (appt.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Complaint: ${appt.reason}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Action Buttons: Call/Remind, Record Vitals (Pre-doctor), Collect Fee
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 1. Call / Remind Button
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dialing ${appt.patientName} (${appt.patientPhone}) to remind/confirm slot...'),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.phone_outlined, size: 15, color: AppTheme.primary),
                label: Text('Call / Remind', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  side: const BorderSide(color: AppTheme.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // 2. Record Vitals (Pre-Doctor Counter Task)
              ElevatedButton.icon(
                onPressed: () => _showRecordVitalsDialog(context, appt, state),
                icon: Icon(hasOp ? Icons.check_circle_outline_rounded : Icons.monitor_heart_outlined, size: 15, color: Colors.white),
                label: Text(
                  hasOp ? 'Vitals Checked ✓' : 'Record Vitals (BP / Wt)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasOp ? const Color(0xFF0284C7) : AppTheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // 3. Collect Fee Button (if pending)
              if (!appt.isFeePaid)
                OutlinedButton.icon(
                  onPressed: () => _showCollectFeeDialog(context, appt, state),
                  icon: const Icon(Icons.payment_rounded, size: 15, color: Color(0xFFB45309)),
                  label: Text('Collect Fee', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFB45309))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    side: const BorderSide(color: Color(0xFFFDE68A), width: 1.2),
                    backgroundColor: const Color(0xFFFEF3C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
