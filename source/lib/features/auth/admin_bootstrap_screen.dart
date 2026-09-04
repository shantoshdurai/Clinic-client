import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/clinic_state_provider.dart';
import '../../services/auth_service.dart';
import '../admin/admin_panel_screen.dart';

/// One-time claim of the Super Admin account on a freshly deployed clinic.
///
/// This screen is reachable only while `clinic_settings/bootstrap` is absent,
/// and creating the admin writes that document — which the Firestore rules
/// also check, so the claim closes on the server and not merely in the UI. It
/// is the only place an admin account is ever created; the Admin console can
/// mint doctors and reception staff, never another admin.
class AdminBootstrapScreen extends StatefulWidget {
  const AdminBootstrapScreen({super.key});

  @override
  State<AdminBootstrapScreen> createState() => _AdminBootstrapScreenState();
}

class _AdminBootstrapScreenState extends State<AdminBootstrapScreen> {
  final _clinicNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _setupKeyController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMessage;

  @override
  void dispose() {
    _clinicNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _setupKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter the administrator\'s full name.');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter an email address for the admin login.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'The two passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final admin = await _authService.claimSuperAdmin(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        setupKey: _setupKeyController.text,
        clinicName: _clinicNameController.text,
      );
      if (!mounted) return;

      context.read<ClinicStateProvider>().setAuthenticatedUser(admin);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        (route) => false,
      );
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
        _errorMessage = 'Setup failed. Check the connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Clinic Setup',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppTheme.textPrimary),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Super Admin', style: AppTheme.serifHero(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  'This runs once. The Super Admin can rename the clinic, add '
                  'and edit doctors, create reception logins, and see every '
                  'report — all of it live, without a new app build.',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5, height: 1.5, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),

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

                _label('Clinic Name'),
                _field(
                  controller: _clinicNameController,
                  hint: 'e.g. AS Clinic',
                  icon: Icons.local_hospital_outlined,
                  capitalize: true,
                ),
                const SizedBox(height: 16),

                _label('Administrator Full Name'),
                _field(
                  controller: _nameController,
                  hint: 'e.g. Dr. Raj Saravanan',
                  icon: Icons.person_outline_rounded,
                  capitalize: true,
                ),
                const SizedBox(height: 16),

                _label('Admin Email (this becomes the login)'),
                _field(
                  controller: _emailController,
                  hint: 'admin@yourclinic.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _label('Password (min 8 characters)'),
                _field(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 16),

                _label('Confirm Password'),
                _field(
                  controller: _confirmController,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                ),
                const SizedBox(height: 16),

                _label('Setup Key'),
                _field(
                  controller: _setupKeyController,
                  hint: 'Provided by your developer',
                  icon: Icons.vpn_key_outlined,
                ),
                const SizedBox(height: 8),
                Text(
                  'The setup key stops anyone else claiming this clinic before '
                  'you do. Ask your developer for it.',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5, height: 1.4, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
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
                            'Create Super Admin',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppTheme.textPrimary),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    bool capitalize = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      enabled: !_isLoading,
      autocorrect: false,
      textCapitalization:
          capitalize ? TextCapitalization.words : TextCapitalization.none,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
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
      ),
    );
  }
}
