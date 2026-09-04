import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/clinic_state_provider.dart';
import '../../auth/patient_login_screen.dart';
import 'quick_contact_sheet.dart';

class ClinicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;

  const ClinicAppBar({super.key, required this.title, this.extraActions});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);

    return AppBar(
      titleSpacing: 20,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.clinicName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                state.clinicTagline,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (extraActions != null) ...extraActions!,

        // Quick Clinic Contact Modal
        IconButton(
          tooltip: 'Quick Contact',
          icon: const Icon(Icons.phone_outlined, color: AppTheme.textPrimary, size: 21),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const QuickContactSheet(),
            );
          },
        ),

        // Notifications
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimary, size: 22),
              onPressed: () => _showNotifications(context, state),
            ),
            if (state.notifications.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),

        // Logout
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted, size: 20),
          onPressed: () async {
            final navigator = Navigator.of(context);
            await state.logout();
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const PatientLoginScreen()),
              (route) => false,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showNotifications(BuildContext context, ClinicStateProvider state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 420,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: AppTheme.serifSubtitle(fontSize: 20)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
              ],
            ),
            const Divider(),
            if (state.notifications.isEmpty)
              Expanded(
                child: Center(
                  child: Text('No notifications', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = state.notifications[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n['title'] ?? '',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n['body'] ?? '',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
