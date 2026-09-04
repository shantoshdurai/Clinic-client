import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../providers/clinic_state_provider.dart';
import '../../services/auth_service.dart';
import '../admin/admin_panel_screen.dart';
import '../doctor/doctor_main_screen.dart';
import '../staff/staff_main_screen.dart';
import 'admin_bootstrap_screen.dart';

/// Email + password sign-in for reception, doctors and the Super Admin.
///
/// The role is whatever `users/{uid}` says in Firestore — it is never picked
/// on this screen and never guessed from the email address.
class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _needsSetup = false;

  @override
  void initState() {
    super.initState();
    _checkBootstrapState();
  }

  /// Offers the one-time Super Admin claim only while the clinic has none.
  Future<void> _checkBootstrapState() async {
    final needs = await _authService.needsSuperAdminSetup();
    if (!mounted) return;
    setState(() => _needsSetup = needs);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;

      context.read<ClinicStateProvider>().setAuthenticatedUser(user);
      _routeForRole(user);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  void _routeForRole(AppUser user) {
    final Widget destination;
    switch (user.role) {
      case UserRole.admin:
        destination = const AdminPanelScreen();
        break;
      case UserRole.doctor:
        destination = const DoctorMainScreen();
        break;
      case UserRole.staff:
        destination = const StaffMainScreen();
        break;
      case UserRole.customer:
        // Refused inside AuthService; kept here so the switch is exhaustive.
        setState(() {
          _isLoading = false;
          _errorMessage = 'This login is for clinic staff only.';
        });
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage =
          'Type your email address first, then tap "Forgot password".');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset link sent to $email',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicName = context.select<ClinicStateProvider, String>((s) => s.clinicName);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.local_hospital_rounded,
                        size: 30, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Staff Sign In', style: AppTheme.serifHero(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  'Reception, Doctor and Admin access for $clinicName. '
                  'Your access level is set by the clinic administrator.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                Text('Email Address',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_isLoading,
                  autofillHints: const [AutofillHints.username],
                  decoration: _fieldDecoration(
                    hint: 'you@clinic.com',
                    icon: Icons.mail_outline_rounded,
                  ),
                ),
                const SizedBox(height: 20),

                Text('Password',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  autofillHints: const [AutofillHints.password],
                  decoration: _fieldDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onSubmitted: (_) => _isLoading ? null : _handleLogin(),
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            'Sign In',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'QUICK 1-TAP LOGIN FOR TESTING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppTheme.border)),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _quickRoleButton(
                        title: 'Super Admin',
                        subtitle: 'admin@clinic.com',
                        icon: Icons.admin_panel_settings_rounded,
                        color: AppTheme.purple,
                        onTap: () async {
                          final creds = await _authService.getAdminCredentials();
                          _emailController.text = creds['email'] ?? AppConfig.defaultAdminEmail;
                          _passController.text = creds['password'] ?? AppConfig.defaultAdminPassword;
                          _handleLogin();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _quickRoleButton(
                        title: 'Doctor',
                        subtitle: 'doctor@clinic.com',
                        icon: Icons.medical_services_rounded,
                        color: AppTheme.secondary,
                        onTap: () {
                          _emailController.text = AppConfig.defaultDoctorEmail;
                          _passController.text = AppConfig.defaultDoctorPassword;
                          _handleLogin();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _quickRoleButton(
                        title: 'Receptionist',
                        subtitle: 'staff@clinic.com',
                        icon: Icons.support_agent_rounded,
                        color: AppTheme.primary,
                        onTap: () {
                          _emailController.text = AppConfig.defaultStaffEmail;
                          _passController.text = AppConfig.defaultStaffPassword;
                          _handleLogin();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Super Admin credentials can be customized anytime under Admin Settings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.8)),
    );
  }
}
