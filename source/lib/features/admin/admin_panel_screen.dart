import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../providers/clinic_state_provider.dart';
import '../auth/patient_login_screen.dart';
import '../billing/billing_reports_screen.dart';
import '../doctor/doctor_main_screen.dart';
import '../pharmacy/pharmacy_inventory_screen.dart';
import '../staff/staff_main_screen.dart';
import 'admin_clinic_settings_screen.dart';
import 'admin_credentials_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_users_screen.dart';

/// Super Admin home.
///
/// Everything the clinic owner asked to be able to change without a developer
/// lives one tap from here: the clinic's own name and details, the doctor
/// roster, and who can sign in. The figures shown are today's real
/// collections — there are no illustrative numbers on this screen.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ClinicStateProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          titleSpacing: Navigator.canPop(context) ? 0 : 20,
          backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.purpleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: AppTheme.purple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Super Admin',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${state.clinicName} • ${state.currentUser?.name ?? ''}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded,
                color: AppTheme.textMuted, size: 20),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.syncError != null) ...[
              _syncBanner(context, state),
              const SizedBox(height: 16),
            ],

            Text('Clinic Configuration', style: AppTheme.serifSubtitle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              'Live across every device. No reinstall needed.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),

            _navTile(
              context,
              title: 'Clinic Profile',
              subtitle: state.settings.phone.isEmpty
                  ? 'Name, address, phone, hours, default fee'
                  : '${state.clinicName} • ${state.settings.phone}',
              icon: Icons.storefront_rounded,
              color: AppTheme.primary,
              destination: const AdminClinicSettingsScreen(),
            ),
            const SizedBox(height: 10),
            _navTile(
              context,
              title: 'Doctors',
              subtitle: state.doctors.isEmpty
                  ? 'No doctors added yet'
                  : '${state.doctors.length} on roster • '
                      '${state.activeDoctors.length} active',
              icon: Icons.medical_services_rounded,
              color: AppTheme.secondary,
              destination: const AdminDoctorsScreen(),
            ),
            const SizedBox(height: 10),
            _navTile(
              context,
              title: 'Login Accounts',
              subtitle: '${state.staffUsers.length} account'
                  '${state.staffUsers.length == 1 ? '' : 's'} • '
                  'create doctor & reception logins',
              icon: Icons.manage_accounts_rounded,
              color: AppTheme.purple,
              destination: const AdminUsersScreen(),
            ),
            const SizedBox(height: 10),
            _navTile(
              context,
              title: 'Admin Credentials',
              subtitle: 'Change Super Admin login email and password',
              icon: Icons.lock_reset_rounded,
              color: AppTheme.accentGreen,
              destination: const AdminCredentialsScreen(),
            ),

            const SizedBox(height: 24),
            Text('Clinic Operations', style: AppTheme.serifSubtitle(fontSize: 20)),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _squareTile(
                    context,
                    title: 'Reception Desk',
                    subtitle: '${state.todayPatientCount} today',
                    icon: Icons.support_agent_rounded,
                    color: AppTheme.warning,
                    destination: const StaffMainScreen(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _squareTile(
                    context,
                    title: 'Doctor Cabin',
                    subtitle: 'Queue & consultation',
                    icon: Icons.medical_information_rounded,
                    color: AppTheme.primary,
                    destination: const DoctorMainScreen(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _squareTile(
                    context,
                    title: 'Financial Reports',
                    subtitle: 'Collections & handovers',
                    icon: Icons.analytics_rounded,
                    color: AppTheme.secondary,
                    destination: const BillingReportsScreen(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _squareTile(
                    context,
                    title: 'Pharmacy',
                    subtitle: '${state.pharmacyItems.length} medicines',
                    icon: Icons.medication_rounded,
                    color: AppTheme.purple,
                    destination: const PharmacyInventoryScreen(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            _dangerZone(context, state),
            const SizedBox(height: 28),
          ],
        ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Widget _syncBanner(BuildContext context, ClinicStateProvider state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.syncError!,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, height: 1.45, color: const Color(0xFF92400E)),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF92400E)),
            onPressed: state.clearSyncError,
          ),
        ],
      ),
    );
  }

  Widget _navTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
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
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _squareTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _dangerZone(BuildContext context, ClinicStateProvider state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 19, color: AppTheme.danger),
              const SizedBox(width: 8),
              Text('Danger Zone',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.danger)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Clears every patient, visit, bill and prescription from the '
            'clinic — on all devices. Staff accounts, doctors and clinic '
            'settings are kept. Use this once, after testing, before real '
            'patients start.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, height: 1.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmReset(context, state),
              icon: const Icon(Icons.delete_sweep_outlined,
                  size: 18, color: AppTheme.danger),
              label: Text('Clear all patient & billing data',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppTheme.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFECACA)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
      BuildContext context, ClinicStateProvider state) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Clear all clinic data?',
              style: AppTheme.serifSubtitle(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This permanently deletes ${state.patients.length} patients, '
                '${state.opVisits.length} visits and '
                '${state.payments.length} bills. It cannot be undone.\n\n'
                'Type DELETE to confirm.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'DELETE'),
                onChanged: (_) => setDlg(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: controller.text.trim().toUpperCase() == 'DELETE'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: Text('Delete everything',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: controller.text.trim().toUpperCase() == 'DELETE'
                          ? AppTheme.danger
                          : AppTheme.textMuted)),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (confirmed != true) return;

    final ok = await state.resetClinicalData();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Clinic data cleared.' : 'Could not clear data. Check the connection.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ok ? AppTheme.primary : AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
