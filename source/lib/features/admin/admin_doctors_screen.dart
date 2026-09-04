import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/doctor.dart';
import '../../providers/clinic_state_provider.dart';

/// Super Admin editor for the clinic's doctor roster.
///
/// This is what replaces editing `clinic_data.dart` and shipping a new APK:
/// the doctor's real name, qualification and consultation fee are Firestore
/// records, so the OP desk, the queue and every printed bill pick up an edit
/// immediately.
class AdminDoctorsScreen extends StatelessWidget {
  const AdminDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ClinicStateProvider>();
    final doctors = state.doctors;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Doctors',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.textPrimary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Doctor',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: doctors.isEmpty
          ? _emptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              itemCount: doctors.length,
              itemBuilder: (_, i) => _doctorCard(context, state, doctors[i]),
            ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.medical_services_outlined,
                  size: 36, color: AppTheme.primaryDark),
            ),
            const SizedBox(height: 18),
            Text('No doctors yet', style: AppTheme.serifSubtitle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Add the clinic\'s doctors here. Their names appear on OP tokens, '
              'the waiting queue, prescriptions and bills.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doctorCard(BuildContext context, ClinicStateProvider state, Doctor doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: doc.active ? AppTheme.border : AppTheme.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: doc.active ? AppTheme.primaryLight : AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medical_services_rounded,
                    color: doc.active ? AppTheme.primaryDark : AppTheme.textMuted,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: doc.active ? AppTheme.textPrimary : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.qualification}  •  ₹${doc.consultationFee.toInt()}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    if (doc.specialty.isNotEmpty)
                      Text(
                        doc.specialty,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                  ],
                ),
              ),
              if (!doc.active)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Inactive',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted)),
                ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              _action(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => _openEditor(context, doc),
              ),
              const SizedBox(width: 8),
              _action(
                icon: doc.active
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                label: doc.active ? 'Hide' : 'Activate',
                onTap: () => state.setDoctorActive(doc.id, !doc.active),
              ),
              const SizedBox(width: 8),
              _action(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                danger: true,
                onTap: () => _confirmDelete(context, state, doc),
              ),
            ],
          ),
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
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ClinicStateProvider state, Doctor doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${doc.name}?',
            style: AppTheme.serifSubtitle(fontSize: 18)),
        content: Text(
          'Past visits, bills and prescriptions keep the doctor\'s name and are '
          'not affected. If you only want to stop new bookings, use Hide '
          'instead.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800, color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.deleteDoctor(doc.id);
    }
  }

  void _openEditor(BuildContext context, Doctor? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoctorEditorSheet(existing: existing),
    );
  }
}

class _DoctorEditorSheet extends StatefulWidget {
  final Doctor? existing;
  const _DoctorEditorSheet({this.existing});

  @override
  State<_DoctorEditorSheet> createState() => _DoctorEditorSheetState();
}

class _DoctorEditorSheetState extends State<_DoctorEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _qualification;
  late final TextEditingController _specialty;
  late final TextEditingController _experience;
  late final TextEditingController _fee;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    final defaultFee = context.read<ClinicStateProvider>().defaultConsultationFee;
    _name = TextEditingController(text: d?.name ?? '');
    _qualification = TextEditingController(text: d?.qualification ?? '');
    _specialty = TextEditingController(text: d?.specialty ?? '');
    _experience = TextEditingController(text: d?.experienceYears ?? '');
    _fee = TextEditingController(
        text: (d?.consultationFee ?? defaultFee).toStringAsFixed(0));
    _phone = TextEditingController(text: d?.phone ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _qualification, _specialty, _experience, _fee, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _toast('Enter the doctor\'s name.', isError: true);
      return;
    }
    setState(() => _saving = true);

    final state = context.read<ClinicStateProvider>();
    // Held before the sheet closes; the sheet's own context is gone after pop.
    final messenger = ScaffoldMessenger.of(context);
    final base = widget.existing;
    final doctor = Doctor(
      id: base?.id ?? state.newDoctorId(),
      name: _name.text.trim(),
      qualification: _qualification.text.trim(),
      specialty: _specialty.text.trim().isEmpty
          ? 'General Physician'
          : _specialty.text.trim(),
      experienceYears: _experience.text.trim(),
      consultationFee:
          double.tryParse(_fee.text.trim()) ?? state.defaultConsultationFee,
      phone: _phone.text.trim(),
      availableBranchIds: base?.availableBranchIds ?? const ['main_clinic'],
      schedules: base?.schedules ?? const [],
      photoUrl: base?.photoUrl ?? '',
      rating: base?.rating ?? 0.0,
      reviewsCount: base?.reviewsCount ?? 0,
      active: base?.active ?? true,
    );

    final ok = await state.saveDoctor(doctor);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      messenger.showSnackBar(
          _snackBar(base == null ? 'Doctor added.' : 'Doctor updated.'));
    } else {
      messenger.showSnackBar(_snackBar(
          'Could not save. You must be signed in as Super Admin.',
          isError: true));
    }
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(_snackBar(message, isError: isError));
  }

  SnackBar _snackBar(String message, {bool isError = false}) {
    return SnackBar(
      content: Text(message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppTheme.danger : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Text(widget.existing == null ? 'Add Doctor' : 'Edit Doctor',
                    style: AppTheme.serifTitle(fontSize: 20)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20)),
              ],
            ),
            const SizedBox(height: 10),

            _field(_name, 'Full Name *', Icons.person_outline,
                hint: 'e.g. Dr. Raj Saravanan', capitalize: true),
            _field(_qualification, 'Qualification', Icons.school_outlined,
                hint: 'e.g. MBBS, MD (General Medicine)'),
            _field(_specialty, 'Specialty', Icons.medical_information_outlined,
                hint: 'e.g. General Medicine & Diabetology', capitalize: true),
            _field(_experience, 'Experience', Icons.timeline_rounded,
                hint: 'e.g. 14+ Years'),
            _field(_fee, 'Consultation Fee (₹)', Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly]),
            _field(_phone, 'Contact Number', Icons.call_outlined,
                keyboardType: TextInputType.phone),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
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
                    : Text(
                        widget.existing == null ? 'Add Doctor' : 'Save Changes',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
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
        textCapitalization:
            capitalize ? TextCapitalization.words : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.textMuted, fontSize: 12.5),
          prefixIcon: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
