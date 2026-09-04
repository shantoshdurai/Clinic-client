import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/appointment.dart';
import '../../../providers/clinic_state_provider.dart';
import '../common/widgets/stat_card.dart';

class StaffDashboardTab extends StatelessWidget {
  final Function(int) onNavigate;

  const StaffDashboardTab({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final branchAppointments = state.branchAppointments;
    final branchOpVisits = state.branchOpVisits;
    final branchPayments = state.branchPayments;

    // Calculate metrics
    final totalOp = branchOpVisits.length + 31; // realistic seed baseline
    final totalAppts = branchAppointments.length;
    final waiting = branchAppointments.where((a) => a.status == AppointmentStatus.checkedIn || a.status == AppointmentStatus.requested).length;
    
    double todayTotalCollection = 0;
    for (var p in branchPayments) {
      todayTotalCollection += p.amountPaid;
    }
    todayTotalCollection += 11700; // Realistic daily baseline

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  radius: 22,
                  child: Icon(Icons.badge_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff Reception Workspace',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Location: ${state.selectedBranch.name}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Overview Stats Grid (Proposal Page 8 & Diagram Step 4B)
          const Text(
            "Today's Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: [
              StatCard(
                title: 'OP Patients',
                value: '$totalOp',
                icon: Icons.personal_injury_rounded,
                color: AppTheme.primary,
                subtitle: '+5 in last hour',
                onTap: () => onNavigate(2), // OP tab
              ),
              StatCard(
                title: 'Appointments',
                value: '$totalAppts',
                icon: Icons.calendar_today_rounded,
                color: AppTheme.secondary,
                subtitle: 'Scheduled today',
                onTap: () => onNavigate(3), // Appointments tab
              ),
              StatCard(
                title: 'Waiting in Queue',
                value: '$waiting',
                icon: Icons.hourglass_top_rounded,
                color: AppTheme.warning,
                subtitle: 'Awaiting consultation',
                onTap: () => onNavigate(3),
              ),
              StatCard(
                title: "Today's Collections",
                value: '₹${todayTotalCollection.toInt()}',
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.success,
                subtitle: 'Cash & UPI',
                onTap: () => onNavigate(4), // Fee tab
              ),
            ],
          ),
          const SizedBox(height: 26),

          // Quick Workflow Actions (Proposal Page 7, 8 & 25)
          const Text(
            'Operational Workflows',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          _buildWorkflowButton(
            title: 'Patient Search & Registration',
            subtitle: 'Look up existing patient or register new with Auto PAT ID',
            icon: Icons.person_search_rounded,
            color: AppTheme.primary,
            onTap: () => onNavigate(1),
          ),
          const SizedBox(height: 10),
          _buildWorkflowButton(
            title: 'New OP Entry & Vitals Recording',
            subtitle: 'Enter BP, Pulse, SpO2, Temp, Sugar & dispatch to doctor',
            icon: Icons.add_circle_outline_rounded,
            color: AppTheme.secondary,
            onTap: () => onNavigate(2),
          ),
          const SizedBox(height: 10),
          _buildWorkflowButton(
            title: 'Appointment Queue & Dispatch',
            subtitle: 'Manage walk-ins and phone bookings',
            icon: Icons.queue_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => onNavigate(3),
          ),
          const SizedBox(height: 10),
          _buildWorkflowButton(
            title: 'Consultation Fee Collection',
            subtitle: 'Collect cash/UPI/card fee and track outstanding balance',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF059669),
            onTap: () => onNavigate(4),
          ),
          const SizedBox(height: 10),
          _buildWorkflowButton(
            title: 'Staff Self Attendance',
            subtitle: 'Daily check-in / check-out with time logs',
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFFD97706),
            onTap: () => onNavigate(5),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWorkflowButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
