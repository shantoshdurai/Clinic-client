import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/clinic_state_provider.dart';

/// Super Admin editor for the clinic's own identity.
///
/// Saving writes `clinic_settings/main`, which every signed-in device is
/// already streaming — so the new clinic name appears on the reception desk
/// and the patient app within a second, with no reinstall.
class AdminClinicSettingsScreen extends StatefulWidget {
  const AdminClinicSettingsScreen({super.key});

  @override
  State<AdminClinicSettingsScreen> createState() =>
      _AdminClinicSettingsScreenState();
}

class _AdminClinicSettingsScreenState extends State<AdminClinicSettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late final TextEditingController _address;
  late final TextEditingController _locality;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _hours;
  late final TextEditingController _regNumber;
  late final TextEditingController _gst;
  late final TextEditingController _fee;
  late final TextEditingController _patientPrefix;
  late final TextEditingController _billPrefix;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<ClinicStateProvider>().settings;
    _name = TextEditingController(text: s.clinicName);
    _tagline = TextEditingController(text: s.tagline);
    _address = TextEditingController(text: s.address);
    _locality = TextEditingController(text: s.locality);
    _phone = TextEditingController(text: s.phone);
    _whatsapp = TextEditingController(text: s.whatsapp);
    _hours = TextEditingController(text: s.workingHours);
    _regNumber = TextEditingController(text: s.registrationNumber);
    _gst = TextEditingController(text: s.gstNumber);
    _fee = TextEditingController(text: s.defaultConsultationFee.toStringAsFixed(0));
    _patientPrefix = TextEditingController(text: s.patientIdPrefix);
    _billPrefix = TextEditingController(text: s.billPrefix);
  }

  @override
  void dispose() {
    for (final c in [
      _name, _tagline, _address, _locality, _phone, _whatsapp,
      _hours, _regNumber, _gst, _fee, _patientPrefix, _billPrefix,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<ClinicStateProvider>();

    if (_name.text.trim().isEmpty) {
      _toast('Clinic name cannot be empty.', isError: true);
      return;
    }

    setState(() => _saving = true);

    final updated = state.settings.copyWith(
      clinicName: _name.text.trim(),
      tagline: _tagline.text.trim(),
      address: _address.text.trim(),
      locality: _locality.text.trim(),
      phone: _phone.text.trim(),
      whatsapp: _whatsapp.text.trim(),
      workingHours: _hours.text.trim(),
      registrationNumber: _regNumber.text.trim(),
      gstNumber: _gst.text.trim(),
      defaultConsultationFee:
          double.tryParse(_fee.text.trim()) ?? state.settings.defaultConsultationFee,
      patientIdPrefix: _patientPrefix.text.trim().isEmpty
          ? state.settings.patientIdPrefix
          : _patientPrefix.text.trim(),
      billPrefix: _billPrefix.text.trim().isEmpty
          ? state.settings.billPrefix
          : _billPrefix.text.trim(),
    );

    final ok = await state.saveClinicSettings(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      _toast('Clinic details updated on every device.');
      Navigator.pop(context);
    } else {
      _toast(
        'Could not save. Check the connection, and that you are signed in as '
        'Super Admin.',
        isError: true,
      );
    }
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppTheme.danger : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatedAt = context.watch<ClinicStateProvider>().settings.updatedAt;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Clinic Profile',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Icon(Icons.sync_rounded, size: 18, color: AppTheme.primaryDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Changes here are live. Every phone signed in to this '
                      'clinic picks them up straight away.',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5, height: 1.45, color: AppTheme.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _sectionTitle('Identity'),
            _field(_name, 'Clinic Name *', Icons.local_hospital_outlined,
                capitalize: true),
            _field(_tagline, 'Tagline / Subtitle', Icons.short_text_rounded),
            _field(_regNumber, 'Clinic Registration Number',
                Icons.assignment_outlined),
            _field(_gst, 'GST Number (optional)', Icons.receipt_long_outlined),

            const SizedBox(height: 20),
            _sectionTitle('Contact & Location'),
            _field(_address, 'Full Address', Icons.location_on_outlined,
                maxLines: 2, capitalize: true),
            _field(_locality, 'Locality / Area', Icons.map_outlined,
                capitalize: true),
            _field(_phone, 'Clinic Phone', Icons.call_outlined,
                keyboardType: TextInputType.phone),
            _field(_whatsapp, 'WhatsApp Number', Icons.chat_outlined,
                keyboardType: TextInputType.phone),
            _field(_hours, 'Working Hours', Icons.schedule_outlined,
                hint: 'e.g. 08:30 AM - 08:30 PM (Mon - Sat)'),

            const SizedBox(height: 20),
            _sectionTitle('Billing Defaults'),
            _field(_fee, 'Default Consultation Fee (₹)', Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly]),
            _field(_patientPrefix, 'Patient ID Prefix', Icons.tag_rounded,
                hint: 'e.g. P- gives P-101, P-102'),
            _field(_billPrefix, 'Bill Number Prefix', Icons.receipt_outlined,
                hint: 'e.g. BILL gives BILL-20260904-01'),

            if (updatedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Last updated ${updatedAt.day}/${updatedAt.month}/${updatedAt.year}'
                '${context.watch<ClinicStateProvider>().settings.updatedByName.isEmpty ? '' : ' by ${context.watch<ClinicStateProvider>().settings.updatedByName}'}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, color: AppTheme.textMuted),
              ),
            ],

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.4))
                    : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                label: Text(
                  _saving ? 'Saving...' : 'Save & Publish',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppTheme.serifSubtitle(fontSize: 18)),
      );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    int maxLines = 1,
    bool capitalize = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: !_saving,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        textCapitalization:
            capitalize ? TextCapitalization.words : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.textMuted, fontSize: 12.5),
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
