import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/patient.dart';
import '../../../providers/clinic_state_provider.dart';

class PatientRegistrationTab extends StatefulWidget {
  final Function(Patient)? onPatientSelectedForOp;

  const PatientRegistrationTab({super.key, this.onPatientSelectedForOp});

  @override
  State<PatientRegistrationTab> createState() => _PatientRegistrationTabState();
}

class _PatientRegistrationTabState extends State<PatientRegistrationTab> {
  final TextEditingController _searchController = TextEditingController();
  
  // New Patient Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  String _selectedGender = 'Male';
  bool _isRegisteringNew = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final searchResults = state.searchPatients(_searchController.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Switch Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isRegisteringNew ? 'Walk-In Registration' : 'Patient Directory',
                style: AppTheme.serifTitle(fontSize: 22),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isRegisteringNew = !_isRegisteringNew;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isRegisteringNew ? AppTheme.surfaceMuted : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isRegisteringNew ? Icons.search_rounded : Icons.person_add_rounded, size: 16, color: AppTheme.primaryDark),
                      const SizedBox(width: 6),
                      Text(
                        _isRegisteringNew ? 'Search Mode' : '+ New Patient',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!_isRegisteringNew) ...[
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by phone, patient ID or name...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              '${searchResults.length} Patient Records Found',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),

            if (searchResults.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.person_off_outlined, size: 40, color: AppTheme.textMuted),
                    const SizedBox(height: 10),
                    Text('No patient record found matching search.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isRegisteringNew = true;
                          _mobileController.text = _searchController.text;
                        });
                      },
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: const Text('Register New Patient Record'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = searchResults[index];
                  return _buildPatientCard(context, p, state);
                },
              ),
          ] else ...[
            // Registration Form
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assigned Patient ID:',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                          ),
                          Text(
                            state.generateNextPatientId(),
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Full Patient Name *', prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter patient name' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: '10-Digit Mobile Number *', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (val) => val == null || val.trim().length < 10 ? 'Enter valid 10-digit mobile' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Age *', prefixIcon: Icon(Icons.cake_outlined)),
                            validator: (val) => val == null || int.tryParse(val) == null ? 'Enter age' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(labelText: 'Gender'),
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (v) => setState(() => _selectedGender = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Area / Locality *', prefixIcon: Icon(Icons.location_on_outlined)),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter locality' : null,
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _handleRegisterPatient(state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Save & Register Patient Record',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Patient p, ClinicStateProvider state) {
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
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryLight,
                    radius: 20,
                    child: Text(
                      p.gender == 'Male' ? 'M' : 'F',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                      Text('${p.patientId} • Ph: ${p.mobile}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${p.age} yrs', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  p.address,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleRegisterPatient(ClinicStateProvider state) {
    if (_formKey.currentState?.validate() ?? false) {
      final newPat = state.registerPatient(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        gender: _selectedGender,
        age: int.parse(_ageController.text.trim()),
        address: _addressController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Patient registered: ${newPat.name} (${newPat.patientId})'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _isRegisteringNew = false;
        _searchController.text = newPat.patientId;
      });
    }
  }
}
