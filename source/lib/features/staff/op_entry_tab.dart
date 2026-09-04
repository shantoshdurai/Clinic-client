import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/op_visit.dart';
import '../../../models/patient.dart';
import '../../../models/payment.dart';
import '../../../providers/clinic_state_provider.dart';
import '../admin/admin_doctors_screen.dart';

/// Formatter that automatically inserts a '/' in BP input (e.g. 12080 -> 120/80)
class BpInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('/', '').replaceAll(' ', '');
    if (text.length > 6) text = text.substring(0, 6);

    String formatted = text;
    if (text.length > 3) {
      formatted = '${text.substring(0, 3)}/${text.substring(3)}';
    } else if (text.length == 3 && oldValue.text.length < newValue.text.length) {
      formatted = '$text/';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class OpEntryTab extends StatefulWidget {
  final Patient? preselectedPatient;

  const OpEntryTab({super.key, this.preselectedPatient});

  @override
  State<OpEntryTab> createState() => _OpEntryTabState();
}

class _OpEntryTabState extends State<OpEntryTab> {
  // Patient Fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = 'Male';
  String? _selectedPatientId;

  // Doctor & Reason
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  /// Doctor picked from the admin-managed roster. Null when reception typed a
  /// name freehand (a visiting locum, say), in which case the visit is stored
  /// against the typed name with no doctor id.
  String? _selectedDoctorId;

  // Vitals (All Optional - Start Blank)
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _sugarController = TextEditingController();

  // Paid Amount at Reception
  final TextEditingController _paidFeeController = TextEditingController();
  final TextEditingController _paymentNoteController = TextEditingController();
  PaymentMode _paymentMode = PaymentMode.cash;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatient != null) {
      _applyPatient(widget.preselectedPatient!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<ClinicStateProvider>();
      final roster = state.activeDoctors;
      setState(() {
        if (_doctorController.text.trim().isEmpty && roster.isNotEmpty) {
          _doctorController.text = roster.first.displayName;
          _selectedDoctorId = roster.first.id;
        }
        _paidFeeController.text = state.defaultConsultationFee.toStringAsFixed(0);
      });
    });
  }

  void _applyPatient(Patient p) {
    setState(() {
      _selectedPatientId = p.patientId;
      _nameController.text = p.name;
      _phoneController.text = p.mobile;
      _ageController.text = p.age.toString();
      _gender = p.gender;
    });
  }

  void _resetForm() {
    setState(() {
      _selectedPatientId = null;
      _nameController.clear();
      _phoneController.clear();
      _ageController.clear();
      _gender = 'Male';
      _reasonController.clear();
      _bpController.clear();
      _weightController.clear();
      _heightController.clear();
      _pulseController.clear();
      _tempController.clear();
      _spo2Controller.clear();
      _sugarController.clear();
      _paidFeeController.text = '500';
      _paymentNoteController.clear();
      _paymentMode = PaymentMode.cash;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _doctorController.dispose();
    _reasonController.dispose();
    _bpController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    _sugarController.dispose();
    _paidFeeController.dispose();
    _paymentNoteController.dispose();
    super.dispose();
  }

  double? _calculateBmi() {
    final w = double.tryParse(_weightController.text.trim());
    final h = double.tryParse(_heightController.text.trim());
    if (w != null && h != null && h >= 50 && h <= 250 && w > 0) {
      final hM = h / 100.0;
      return double.parse((w / (hM * hM)).toStringAsFixed(1));
    }
    return null;
  }

  void _showPatientPickerSheet(BuildContext context, ClinicStateProvider state) {
    if (state.patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No registered patients in database yet. Type details directly below.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Registered Patient (${state.patients.length})', style: AppTheme.serifTitle(fontSize: 18)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: state.patients.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final p = state.patients[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                    ),
                    title: Text(p.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text('${p.patientId} • Ph: ${p.mobile} • ${p.age}y/${p.gender}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _applyPatient(p);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOpSubmit(BuildContext context, ClinicStateProvider state) {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter patient name'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter patient mobile number'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Auto register or reuse patient
    final age = int.tryParse(_ageController.text.trim()) ?? 30;
    String patientId = _selectedPatientId ?? '';

    if (patientId.isEmpty) {
      final existing = state.patients.where((p) => p.mobile == phone).toList();
      if (existing.isNotEmpty) {
        patientId = existing.first.patientId;
      } else {
        final newPat = state.registerPatient(
          name: name,
          mobile: phone,
          gender: _gender,
          age: age,
          address: '',
        );
        patientId = newPat.patientId;
      }
    }

    // Doctor name, and the roster id behind it when there is one. The doctor
    // dashboards filter on this id, so a synthetic hash would silently hide
    // the visit from the doctor's own queue.
    final roster = state.activeDoctors;
    var docName = _doctorController.text.trim();
    if (docName.isEmpty) {
      docName = roster.isNotEmpty ? roster.first.displayName : 'Doctor';
    }
    final rosterMatch = roster
        .where((d) => d.displayName == docName || d.id == _selectedDoctorId);
    final docId = rosterMatch.isNotEmpty ? rosterMatch.first.id : '';

    // Build Vitals (Optional)
    final bp = _bpController.text.trim().isNotEmpty ? _bpController.text.trim() : null;
    final vitals = Vitals(
      bp: bp,
      weightKg: double.tryParse(_weightController.text.trim()),
      heightCm: double.tryParse(_heightController.text.trim()),
      pulseBpm: int.tryParse(_pulseController.text.trim()),
      temperatureF: double.tryParse(_tempController.text.trim()),
      spo2Percent: int.tryParse(_spo2Controller.text.trim()),
      bloodSugarMgDl: int.tryParse(_sugarController.text.trim()),
    );

    final reason = _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : 'General Consultation';

    // Amount paid at reception
    final paidAmount = double.tryParse(_paidFeeController.text.trim()) ?? 0.0;
    final note = _paymentNoteController.text.trim();

    final op = state.createOpVisit(
      patientId: patientId,
      patientName: name,
      patientPhone: phone,
      doctorId: docId,
      doctorName: docName,
      reasonForVisit: reason,
      vitals: vitals,
      consultationFee:
          paidAmount > 0 ? paidAmount : state.defaultConsultationFee,
      initialPaid: paidAmount,
      initialMode: _paymentMode,
      collectNow: paidAmount > 0,
    );

    // Reset form immediately and scroll to top
    _resetForm();

    // Show prominent floating green SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Token #${op.tokenNumber} created for ${op.patientName}! Sent to Doctor Cabin.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    // Show Confirmation Dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 36),
            ),
            const SizedBox(height: 12),
            Text('Token #${op.tokenNumber} Issued!', style: AppTheme.serifTitle(fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${op.patientName} (${op.patientId})',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Doctor: $docName', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text(
              paidAmount > 0
                  ? 'Fee Collected: ₹${paidAmount.toInt()} (${_paymentMode.label})'
                  : 'Fee Status: Pending / Collect in Cabin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: paidAmount > 0 ? AppTheme.success : AppTheme.warning,
              ),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Note: $note', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: AppTheme.primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live synced with Doctor Cabin waiting queue.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK • Next Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final bmi = _calculateBmi();
    final paidAmount = double.tryParse(_paidFeeController.text.trim()) ?? 0.0;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OP Registration & Token Desk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Issue Token #${state.opVisits.length + 1} • Auto-Sync with Doctor Cabin',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_selectedPatientId != null || _nameController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Patient Details Card
          Container(
            padding: const EdgeInsets.all(18),
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
                    Text(
                      '1. Patient Details',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    InkWell(
                      onTap: () => _showPatientPickerSheet(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_alt_outlined, size: 14, color: AppTheme.primaryDark),
                            const SizedBox(width: 4),
                            Text('Pick Patient (${state.patients.length})',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Name
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Full Name *',
                    hintText: 'e.g. Ramesh Kumar',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    if (val.trim().length >= 10) {
                      final match = state.patients.where((p) => p.mobile == val.trim()).toList();
                      if (match.isNotEmpty) {
                        _applyPatient(match.first);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Age & Gender
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age (Yrs)',
                          hintText: 'e.g. 35',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _gender,
                            isExpanded: true,
                            items: ['Male', 'Female', 'Other'].map((g) {
                              return DropdownMenuItem(
                                value: g,
                                child: Text(g, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Doctor & Symptoms
          Container(
            padding: const EdgeInsets.all(18),
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
                    Text(
                      '2. Consulting Doctor & Symptoms',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    if (state.isAdmin)
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminDoctorsScreen()),
                        ),
                        child: Text(
                          'Manage (${state.activeDoctors.length})',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Doctor Field with Dropdown + Add Option
                TextField(
                  controller: _doctorController,
                  decoration: InputDecoration(
                    labelText: 'Doctor Name (Type or Select)',
                    hintText: 'Select from the clinic roster',
                    prefixIcon: const Icon(Icons.medical_services_outlined),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.primary),
                      tooltip: 'Select Doctor',
                      onSelected: (val) {
                        final picked = state.activeDoctors.where((d) => d.id == val);
                        setState(() {
                          _selectedDoctorId = val;
                          if (picked.isNotEmpty) {
                            _doctorController.text = picked.first.displayName;
                          }
                        });
                      },
                      itemBuilder: (ctx) => state.activeDoctors.isEmpty
                          ? [
                              const PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  'No doctors yet. The admin adds them under Admin > Doctors.',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ]
                          : state.activeDoctors
                              .map((doc) => PopupMenuItem<String>(
                                    value: doc.id,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: AppTheme.primary),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(doc.displayName,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Symptoms / Chief Complaint (Optional)',
                    hintText: 'e.g. Fever, cough, general checkup',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Vitals (All Optional - Auto "/" in BP)
          Container(
            padding: const EdgeInsets.all(18),
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
                    Row(
                      children: [
                        const Icon(Icons.monitor_heart_rounded, color: AppTheme.danger, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '3. Patient Vitals (Optional)',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    if (bmi != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'BMI: $bmi',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 11.5, color: AppTheme.primaryDark),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Leave blank if not measured. BP auto-inserts "/" as you type.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textMuted)),
                const SizedBox(height: 14),

                // Row 1: BP (with auto-slash) & Pulse
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [BpInputFormatter()],
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'BP (mmHg)',
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          hintText: '120/80',
                          prefixIcon: Icon(Icons.speed_rounded, size: 18, color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _pulseController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Pulse (bpm)',
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          hintText: '72',
                          prefixIcon: Icon(Icons.favorite_outline_rounded, size: 18, color: AppTheme.danger),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Weight & Height
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          hintText: '65.0',
                          prefixIcon: Icon(Icons.scale_rounded, size: 18, color: AppTheme.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          hintText: '168.0',
                          prefixIcon: Icon(Icons.height_rounded, size: 18, color: AppTheme.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 3: Temp, SpO2, Sugar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tempController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Temp (°F)',
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 12),
                          hintText: '98.4',
                          prefixIcon: Icon(Icons.thermostat_rounded, size: 16, color: Color(0xFFD97706)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _spo2Controller,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'SpO2 (%)',
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 12),
                          hintText: '99',
                          prefixIcon: Icon(Icons.air_rounded, size: 16, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _sugarController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Sugar',
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 12),
                          hintText: '100',
                          prefixIcon: Icon(Icons.water_drop_outlined, size: 16, color: Color(0xFF059669)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Initial Fee Collection at Reception
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: paidAmount > 0 ? AppTheme.primary : AppTheme.border,
                width: paidAmount > 0 ? 1.5 : 1,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '4. Counter Fee Collection',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: paidAmount > 0 ? AppTheme.primaryLight : AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        paidAmount > 0 ? '₹${paidAmount.toInt()} Collected' : 'Pay in Cabin',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          color: paidAmount > 0 ? AppTheme.primaryDark : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Amount Paid Now Field
                TextField(
                  controller: _paidFeeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid at Reception (₹)',
                    hintText: '500',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Preset Chips for Paid amount
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAmountChip('₹500', '500'),
                      const SizedBox(width: 6),
                      _buildAmountChip('₹300', '300'),
                      const SizedBox(width: 6),
                      _buildAmountChip('₹200', '200'),
                      const SizedBox(width: 6),
                      _buildAmountChip('₹100', '100'),
                      const SizedBox(width: 6),
                      _buildAmountChip('₹0 (Pay Later)', '0'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Payment Method
                Text('Payment Mode:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _paymentMode = PaymentMode.cash),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('Cash'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _paymentMode == PaymentMode.cash ? AppTheme.primaryLight : Colors.transparent,
                          side: BorderSide(color: _paymentMode == PaymentMode.cash ? AppTheme.primary : AppTheme.border, width: _paymentMode == PaymentMode.cash ? 1.8 : 1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _paymentMode = PaymentMode.upi),
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                        label: const Text('UPI / GPay'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _paymentMode == PaymentMode.upi ? AppTheme.primaryLight : Colors.transparent,
                          side: BorderSide(color: _paymentMode == PaymentMode.upi ? AppTheme.primary : AppTheme.border, width: _paymentMode == PaymentMode.upi ? 1.8 : 1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment Remark Note
                TextField(
                  controller: _paymentNoteController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Note / UPI Ref (Optional)',
                    hintText: 'e.g. GPay Ref #12345 / Token advance',
                    prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Big Bold Save & Send Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _handleOpSubmit(context, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Save & Send to Doctor Queue (Token #${state.opVisits.length + 1})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAmountChip(String label, String value) {
    final isSelected = _paidFeeController.text.trim() == value;
    return InkWell(
      onTap: () {
        setState(() {
          _paidFeeController.text = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
