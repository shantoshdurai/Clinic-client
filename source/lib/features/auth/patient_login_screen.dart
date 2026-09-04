import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/clinic_state_provider.dart';
import '../customer/customer_main_screen.dart';
import 'patient_onboarding_screen.dart';
import 'staff_login_screen.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _phoneDigitsCount = 0;
  int _otpDigitsCount = 0;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() => setState(() {}));
    _otpFocusNode.addListener(() => setState(() {}));

    _phoneController.addListener(() {
      final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (_phoneDigitsCount != digits.length) {
        setState(() {
          _phoneDigitsCount = digits.length;
        });
      }
    });

    _otpController.addListener(() {
      final digits = _otpController.text.replaceAll(RegExp(r'\D'), '');
      if (_otpDigitsCount != digits.length) {
        setState(() {
          _otpDigitsCount = digits.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '').trim();
    if (phone.length < 10) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
        _otpController.text = '123456';
      });

      _otpFocusNode.requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP sent to +91 $phone (Demo: 123456)',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }

  void _verifyOtp() {
    final otp = _otpController.text.replaceAll(RegExp(r'\D'), '').trim();
    if (otp.length < 6) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final state = Provider.of<ClinicStateProvider>(context, listen: false);
      final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '').trim();
      final isExisting = state.loginWithVerifiedPhone(phone);

      if (isExisting) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const CustomerMainScreen(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => PatientOnboardingScreen(verifiedPhone: phone),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final isPhoneValid = _phoneDigitsCount >= 10;
    final isOtpValid = _otpDigitsCount >= 6;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Staff entrance. This is a link to a password-protected sign-in,
              // not a way in: reception, doctor and admin screens are reachable
              // only after Firebase Auth verifies the account and Firestore
              // confirms its role.
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.badge_outlined,
                      size: 16, color: AppTheme.textSecondary),
                  label: Text(
                    'Clinic staff sign in',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Brand Icon (Vibrant green rounded square with white icon)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_hospital_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Welcome Heading & Subtitle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: !_isOtpSent
                    ? Column(
                        key: const ValueKey('phone_title'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to\n${state.clinicName}',
                            style: AppTheme.serifHero(fontSize: 34),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter your mobile number — we\'ll text you a\none-time code.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              color: const Color(0xFF64748B),
                              height: 1.45,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('otp_title'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify your\nnumber',
                            style: AppTheme.serifHero(fontSize: 34),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We sent a 6-digit verification code to\n+91 ${_phoneController.text}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              color: const Color(0xFF64748B),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // The patient portal is still a preview: the OTP is a fixed demo
              // code, not a real SMS, so patient records are not persisted to
              // the clinic database. Reception, Doctor and Admin sign-in are
              // fully live. Say so plainly rather than letting it look broken.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 17, color: Color(0xFFB45309)),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Patient sign-in is a preview — the OTP is a demo code '
                        'until SMS verification is switched on. Clinic staff '
                        'sign-in is live.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              if (!_isOtpSent) ...[
                // "Mobile number" Label
                Text(
                  'Mobile number',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),

                // Mobile Number Input Field with Glowing Sensation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPhoneValid
                          ? AppTheme.accentGreen
                          : (_phoneFocusNode.hasFocus ? AppTheme.accentGreen.withValues(alpha: 0.6) : AppTheme.border),
                      width: isPhoneValid || _phoneFocusNode.hasFocus ? 1.8 : 1,
                    ),
                    boxShadow: isPhoneValid
                        ? [
                            BoxShadow(
                              color: AppTheme.accentGreen.withValues(alpha: 0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        '+91',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: AppTheme.border,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          cursorColor: AppTheme.accentGreen,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: '98765 43210',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isPhoneValid ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Glowing Sensation "Send OTP →" Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isPhoneValid
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isPhoneValid ? null : const Color(0xFFA7F3D0).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isPhoneValid ? AppTheme.glowGreenShadow : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isPhoneValid && !_isLoading ? _sendOtp : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Send OTP',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isPhoneValid ? Colors.white : const Color(0xFF065F46).withValues(alpha: 0.55),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedSlide(
                                    duration: const Duration(milliseconds: 200),
                                    offset: isPhoneValid ? const Offset(0.2, 0) : Offset.zero,
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: isPhoneValid ? Colors.white : const Color(0xFF065F46).withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Compact 6-Box Pin Code OTP Area
                Text(
                  'Enter 6-digit Code',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                // Sleek 6-box OTP Display
                GestureDetector(
                  onTap: () => _otpFocusNode.requestFocus(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Transparent Hidden Text Field to receive keyboard input
                      Opacity(
                        opacity: 0.0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: true,
                        ),
                      ),
                      // 6 Beautiful Compact Digit Boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final text = _otpController.text;
                          final hasDigit = index < text.length;
                          final isCurrent = index == text.length;
                          final digit = hasDigit ? text[index] : '';

                          return Container(
                            width: 44,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasDigit || isCurrent ? AppTheme.accentGreen : AppTheme.border,
                                width: hasDigit || isCurrent ? 1.8 : 1,
                              ),
                              boxShadow: hasDigit
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.accentGreen.withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                digit,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isOtpSent = false),
                      child: Text(
                        'Change number',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _sendOtp,
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Glow-Up "Verify & Continue →" Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isOtpValid
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isOtpValid ? null : const Color(0xFFA7F3D0).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isOtpValid ? AppTheme.glowGreenShadow : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isOtpValid && !_isLoading ? _verifyOtp : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Verify & Continue',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isOtpValid ? Colors.white : const Color(0xFF065F46).withValues(alpha: 0.55),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                    color: isOtpValid ? Colors.white : const Color(0xFF065F46).withValues(alpha: 0.55),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Bottom Privacy Note (DirectNest style)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Your number is never shared with other users.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
