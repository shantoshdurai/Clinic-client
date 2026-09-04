import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/clinic_state_provider.dart';

class DoctorReportsTab extends StatelessWidget {
  const DoctorReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doctor Consultation Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('Clinical volume & revenue metrics summary', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Daily Summary Card (Proposal Page 15: Today's Collection ₹11,500)
          Card(
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
                  const Text("Today's Performance Metrics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  _buildMetricRow('Total Patients Scheduled', '18 Patients', AppTheme.textPrimary),
                  const Divider(height: 14),
                  _buildMetricRow('Completed Consultations', '14 (78% completion)', AppTheme.success),
                  const Divider(height: 14),
                  _buildMetricRow('Avg. Time per Consultation', '12.4 Minutes', AppTheme.secondary),
                  const Divider(height: 14),
                  _buildMetricRow('Total Consultation Fees', '₹11,500', AppTheme.primaryDark),
                  const Divider(height: 14),
                  _buildMetricRow('Follow-ups in Pipeline', '5 Patients', const Color(0xFF7C3AED)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Payment mode split
          Card(
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
                  const Text('Revenue Breakdown by Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  _buildModeBar('UPI / GPay (60%)', '₹7,000', 0.60, const Color(0xFF2563EB)),
                  const SizedBox(height: 12),
                  _buildModeBar('Cash at Reception (35%)', '₹4,000', 0.35, AppTheme.success),
                  const SizedBox(height: 12),
                  _buildModeBar('Credit/Debit Card (5%)', '₹500', 0.05, const Color(0xFFF59E0B)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Upcoming Follow-up Patients List
          const Text('Upcoming Follow-Up Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.prescriptions.where((p) => p.followUpDate != null).length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final rx = state.prescriptions.where((p) => p.followUpDate != null).toList()[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event_repeat, color: AppTheme.secondary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rx.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Due: ${rx.followUpDate} • ${rx.followUpReason}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.notifications_active_outlined, size: 16, color: AppTheme.primary),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildModeBar(String label, String value, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: AppTheme.surfaceMuted,
          color: color,
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}
