import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor.dart';
import '../../models/user_role.dart';
import '../../providers/clinic_state_provider.dart';
import '../../services/auth_service.dart';

/// Super Admin management of who can sign in.
///
/// Creating an account here makes a real Firebase Auth login plus its
/// `users/{uid}` role document. The role picker offers Doctor and Reception
/// only — a second Super Admin cannot be minted from inside the app, which is
/// what keeps "admin" from becoming something anyone can sign up for.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ClinicStateProvider>();
    final users = state.staffUsers;
    final me = state.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Login Accounts',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.textPrimary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _CreateAccountSheet(),
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text('New Account',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 18, color: AppTheme.primaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Each person gets their own email and password. Nobody can '
                    'self-register, and every action is recorded against the '
                    'name that collected or entered it.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5, height: 1.45, color: AppTheme.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.group_outlined, size: 40, color: AppTheme.textMuted),
                  const SizedBox(height: 14),
                  Text('No staff accounts yet',
                      style: AppTheme.serifSubtitle(fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                    'Create a login for the doctor and for the reception desk.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...users.map((u) => _userCard(context, state, u, isSelf: u.id == me?.id)),
        ],
      ),
    );
  }

  Widget _userCard(BuildContext context, ClinicStateProvider state, AppUser user,
      {required bool isSelf}) {
    final isDoctor = user.role == UserRole.doctor;
    final isAdmin = user.role == UserRole.admin;

    final Color badgeBg = isAdmin
        ? AppTheme.purpleLight
        : (isDoctor ? AppTheme.primaryLight : AppTheme.warningLight);
    final Color badgeFg = isAdmin
        ? AppTheme.purple
        : (isDoctor ? AppTheme.primaryDark : const Color(0xFFB45309));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: badgeBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : (isDoctor
                          ? Icons.medical_services_rounded
                          : Icons.support_agent_rounded),
                  color: badgeFg,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: user.active
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Text('(you)',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5, color: AppTheme.textMuted)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(user.emailOrPhone,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeBg, borderRadius: BorderRadius.circular(6)),
                child: Text(user.role.shortName,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w800, color: badgeFg)),
              ),
            ],
          ),
          if (!user.active) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: AppTheme.dangerLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Deactivated — cannot sign in',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.danger)),
            ),
          ],

          // The Super Admin's own account is never disable-able from here —
          // that is the one way to lock everybody out of the clinic.
          if (!isSelf) ...[
            const Divider(height: 22),
            Row(
              children: [
                _action(
                  icon: Icons.lock_reset_rounded,
                  label: 'Reset password',
                  onTap: () => _sendReset(context, user),
                ),
                const SizedBox(width: 8),
                _action(
                  icon: user.active
                      ? Icons.block_rounded
                      : Icons.check_circle_outline_rounded,
                  label: user.active ? 'Deactivate' : 'Activate',
                  danger: user.active,
                  onTap: () => _toggleActive(context, state, user),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppTheme.danger : AppTheme.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: danger ? AppTheme.dangerLight : AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendReset(BuildContext context, AppUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService().sendPasswordResetEmail(user.emailOrPhone);
      messenger.showSnackBar(_snack(
          'Password reset link sent to ${user.emailOrPhone}', AppTheme.primary));
    } on AuthFailure catch (e) {
      messenger.showSnackBar(_snack(e.message, AppTheme.danger));
    }
  }

  Future<void> _toggleActive(
      BuildContext context, ClinicStateProvider state, AppUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    final turningOff = user.active;

    if (turningOff) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Deactivate ${user.name}?',
              style: AppTheme.serifSubtitle(fontSize: 18)),
          content: Text(
            'They will be signed out and blocked from signing in again until '
            'you reactivate the account. Their past records stay intact.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Deactivate',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800, color: AppTheme.danger)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await AuthService().setUserActive(user.id, !user.active);
      messenger.showSnackBar(_snack(
        turningOff ? '${user.name} deactivated.' : '${user.name} reactivated.',
        AppTheme.primary,
      ));
    } catch (e) {
      messenger.showSnackBar(
          _snack('Could not update the account. Try again.', AppTheme.danger));
    }
  }

  static SnackBar _snack(String message, Color color) => SnackBar(
        content: Text(message,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
      );
}

class _CreateAccountSheet extends StatefulWidget {
  const _CreateAccountSheet();

  @override
  State<_CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends State<_CreateAccountSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  UserRole _role = UserRole.staff;
  String? _linkedDoctorId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final state = context.read<ClinicStateProvider>();

    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'Name and email are required.');
      return;
    }
    if (_role == UserRole.doctor && _linkedDoctorId == null) {
      setState(() => _error =
          'Pick which doctor profile this login belongs to, or add the doctor '
          'first under Admin > Doctors.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    // Captured before the sheet is popped — `ScaffoldMessenger.of(context)`
    // on a defunct sheet context would throw instead of showing the message.
    final messenger = ScaffoldMessenger.of(context);
    final createdName = _name.text.trim();

    try {
      await AuthService().createStaffAccount(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
        phone: _phone.text,
        doctorId: _role == UserRole.doctor ? _linkedDoctorId : null,
        staffId: _role == UserRole.staff
            ? 'STF-${state.staffUsers.length + 101}'
            : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(AdminUsersScreen._snack(
          '$createdName can now sign in.', AppTheme.primary));
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not create the account. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctors = context.watch<ClinicStateProvider>().doctors;

    return Container(
      padding: EdgeInsets.only(
        top: 22,
        left: 22,
        right: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
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
                Text('New Login Account',
                    style: AppTheme.serifTitle(fontSize: 20)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Super Admin accounts cannot be created here. That is deliberate — '
              'there is exactly one, claimed during clinic setup.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, height: 1.45, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),

            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF991B1B))),
              ),
              const SizedBox(height: 14),
            ],

            Text('Role',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _roleTile(UserRole.staff, 'Reception', Icons.support_agent_rounded),
                const SizedBox(width: 10),
                _roleTile(UserRole.doctor, 'Doctor', Icons.medical_services_rounded),
              ],
            ),
            const SizedBox(height: 16),

            if (_role == UserRole.doctor) ...[
              if (doctors.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Add the doctor under Admin > Doctors first, then come back '
                    'and create their login.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.4,
                        color: const Color(0xFF92400E)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _linkedDoctorId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Linked Doctor Profile *',
                      prefixIcon: Icon(Icons.link_rounded, size: 20),
                    ),
                    items: doctors
                        .map((Doctor d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _linkedDoctorId = v),
                  ),
                ),
            ],

            _field(_name, 'Full Name *', Icons.person_outline, capitalize: true),
            _field(_email, 'Email (this is the login) *', Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress),
            _field(_phone, 'Mobile Number', Icons.call_outlined,
                keyboardType: TextInputType.phone),
            _field(_password,
                'Temporary Password (min ${AppConfig.minPasswordLength}) *',
                Icons.lock_outline_rounded),

            const SizedBox(height: 4),
            Text(
              'Share this password with them once. They can change it later via '
              '"Forgot password" on the sign-in screen.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5, height: 1.4, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.4))
                    : Text('Create Account',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleTile(UserRole role, String label, IconData icon) {
    final selected = _role == role;
    return Expanded(
      child: InkWell(
        onTap: _saving ? null : () => setState(() => _role = role),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryLight : AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? AppTheme.primaryDark : AppTheme.textMuted,
                  size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.primaryDark
                          : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool capitalize = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: !_saving,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        autocorrect: false,
        textCapitalization:
            capitalize ? TextCapitalization.words : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
