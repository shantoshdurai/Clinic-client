import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/clinic_state_provider.dart';

class DoctorPrescriptionsTab extends StatelessWidget {
  const DoctorPrescriptionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final user = state.currentUser;
    final doctorId = user?.doctorId ?? state.primaryDoctor?.id ?? '';

    final prescriptions = state.prescriptions.where((p) => p.doctorId == doctorId).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Issued Digital Prescriptions', style: AppTheme.serifTitle(fontSize: 22)),
                  Text('All digital prescriptions issued to patients', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Total: ${prescriptions.length}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.primaryDark, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (prescriptions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('No prescriptions recorded yet.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prescriptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rx = prescriptions[index];
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(rx.patientName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppTheme.textPrimary)),
                          Text(rx.date, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${rx.prescriptionNumber} • Patient ID: ${rx.patientId}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primaryDark, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      ...rx.items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(it.medicineName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                            Text('${it.dosagePattern} (${it.durationDays}d)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      )),
                      if (rx.followUpDate != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_repeat_rounded, size: 14, color: Color(0xFFB45309)),
                              const SizedBox(width: 6),
                              Text('Follow-up: ${rx.followUpDate} (${rx.followUpReason})', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF92400E))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
