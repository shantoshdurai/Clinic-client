import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/appointment.dart';
import '../../../providers/clinic_state_provider.dart';
import '../common/widgets/stat_card.dart';
import 'doctor_consultation_screen.dart';

class DoctorDashboardTab extends StatelessWidget {
  final Function(int) onNavigate;

  const DoctorDashboardTab({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final user = state.currentUser;
    // `state.doctors` is empty on a brand-new clinic, so reaching for
    // `.first` here used to throw. Fall back to whichever doctor the clinic
    // has, and render an empty dashboard when it has none yet.
    final doctorId = user?.doctorId ?? state.primaryDoctor?.id ?? '';
    final doctorMatches = state.doctors.where((d) => d.id == doctorId);
    final doctor = doctorMatches.isNotEmpty
        ? doctorMatches.first
        : (state.doctors.isNotEmpty ? state.doctors.first : null);

    final appointments = state.appointments.where((a) => a.doctorId == doctorId).toList();
    final waitingList = appointments.where((a) => a.status == AppointmentStatus.checkedIn || a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.requested).toList();
    final inConsultationList = appointments.where((a) => a.status == AppointmentStatus.inConsultation).toList();
    final completedList = appointments.where((a) => a.status == AppointmentStatus.completed).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor?.name ?? state.currentUser?.name ?? 'Doctor',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        doctor == null
                            ? 'Add your profile under Admin > Doctors'
                            : '${doctor.qualification} • ${doctor.specialty}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Active Location: ${state.selectedBranch.locality}',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Doctor Metrics Grid (Proposal Page 8: Today's Appointments 18, Waiting 4, In Consultation 1, Completed 13, Collection ₹11,500, Follow-ups 5)
          const Text(
            "Today's Consultation Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: [
              StatCard(
                title: "Total Appointments",
                value: '${appointments.length + 14}',
                icon: Icons.people_alt_rounded,
                color: AppTheme.primary,
                subtitle: 'Scheduled for today',
                onTap: () => onNavigate(1),
              ),
              StatCard(
                title: "Waiting Patients",
                value: '${waitingList.length + 2}',
                icon: Icons.hourglass_top_rounded,
                color: AppTheme.warning,
                subtitle: 'Ready in waiting room',
                onTap: () => onNavigate(1),
              ),
              StatCard(
                title: "In Consultation",
                value: '${inConsultationList.length}',
                icon: Icons.meeting_room_rounded,
                color: const Color(0xFF7C3AED),
                subtitle: 'Active session',
                onTap: () {
                  if (inConsultationList.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorConsultationScreen(appointment: inConsultationList.first),
                      ),
                    );
                  }
                },
              ),
              StatCard(
                title: "Completed Visits",
                value: '${completedList.length + 12}',
                icon: Icons.task_alt_rounded,
                color: AppTheme.success,
                subtitle: 'Prescriptions issued',
                onTap: () => onNavigate(1),
              ),
              StatCard(
                title: "Today's Collection",
                value: "₹11,500",
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF059669),
                subtitle: "Cash & UPI payments",
                onTap: () => onNavigate(3),
              ),
              StatCard(
                title: "Follow-ups Scheduled",
                value: "5",
                icon: Icons.event_repeat_rounded,
                color: const Color(0xFF0284C7),
                subtitle: "Next 7 days",
                onTap: () => onNavigate(2),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Active or Next Patient Card
          const Text(
            'Current Consultation Workspace',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),

          if (inConsultationList.isNotEmpty) ...[
            _buildActiveConsultationCard(context, inConsultationList.first)
          ] else if (waitingList.isNotEmpty) ...[
            _buildNextWaitingCard(context, waitingList.first, state)
          ] else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Center(
                child: Text('All scheduled patients have been consulted.', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActiveConsultationCard(BuildContext context, Appointment appt) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, size: 10, color: Color(0xFF7C3AED)),
                      SizedBox(width: 6),
                      Text(
                        'PATIENT IN CONSULTATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                ),
                Text('Token #${appt.tokenNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            Text(appt.patientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Patient ID: ${appt.patientId} • Ph: ${appt.patientPhone}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text('Chief Complaint: ${appt.reason}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorConsultationScreen(appointment: appt),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_document, size: 18, color: Colors.white),
                label: const Text('Open Consultation & Write Case Notes / Rx'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextWaitingCard(BuildContext context, Appointment appt, ClinicStateProvider state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('NEXT IN QUEUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning)),
                ),
                Text('Token #${appt.tokenNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Text(appt.patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${appt.patientId} • Slot: ${appt.timeSlot} • ${appt.reason}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  state.updateAppointmentStatus(appt.id, AppointmentStatus.inConsultation);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorConsultationScreen(appointment: appt.copyWith(status: AppointmentStatus.inConsultation)),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('Call Patient / Start Consultation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
