import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/doctor.dart';
import '../../../providers/clinic_state_provider.dart';

class BookAppointmentTab extends StatefulWidget {
  final Doctor? initialDoctor;
  final VoidCallback? onBookingSuccess;

  const BookAppointmentTab({super.key, this.initialDoctor, this.onBookingSuccess});

  @override
  State<BookAppointmentTab> createState() => _BookAppointmentTabState();
}

class _BookAppointmentTabState extends State<BookAppointmentTab> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController(text: 'General consultation');

  Doctor? _selectedDoctor;
  String _selectedSpecialty = 'All';
  String _selectedDate = '18 Aug 2026';
  String? _selectedTimeSlot;

  final List<String> _specialties = [
    'All',
    'General Medicine',
    'Gynaecology',
    'Orthopaedics',
    'Pediatrics',
  ];

  final List<Map<String, String>> _dateOptions = [
    {'day': 'Today', 'date': '18 Aug 2026', 'dayName': 'Tue'},
    {'day': 'Tomorrow', 'date': '19 Aug 2026', 'dayName': 'Wed'},
    {'day': '20 Aug', 'date': '20 Aug 2026', 'dayName': 'Thu'},
    {'day': '21 Aug', 'date': '21 Aug 2026', 'dayName': 'Fri'},
    {'day': '22 Aug', 'date': '22 Aug 2026', 'dayName': 'Sat'},
    {'day': '24 Aug', 'date': '24 Aug 2026', 'dayName': 'Mon'},
  ];

  final List<String> _morningSlots = [
    '09:00 AM',
    '09:15 AM',
    '09:30 AM',
    '09:45 AM',
    '10:00 AM',
    '10:15 AM',
    '10:30 AM',
    '10:45 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
  ];

  final List<String> _eveningSlots = [
    '04:30 PM',
    '05:00 PM',
    '05:15 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM',
  ];

  final List<String> _quickSymptoms = [
    'Fever & Cold',
    'General Checkup',
    'Headache / Migraine',
    'Joint Pain',
    'Blood Sugar / BP',
    'Stomach Pain',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDoctor = widget.initialDoctor;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final user = state.currentUser;
    final patient = state.patients.firstWhere(
      (p) => p.patientId == (user?.patientId ?? 'PAT-000123'),
      orElse: () => state.patients.first,
    );

    // Filter doctors
    final doctors = state.doctors.where((doc) {
      final matchesSpecialty = _selectedSpecialty == 'All' || doc.specialty.contains(_selectedSpecialty);
      final query = _searchController.text.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          doc.name.toLowerCase().contains(query) ||
          doc.specialty.toLowerCase().contains(query) ||
          doc.qualification.toLowerCase().contains(query);
      return matchesSpecialty && matchesSearch;
    }).toList();

    // Auto select first doctor if none selected
    if (_selectedDoctor == null && doctors.isNotEmpty) {
      _selectedDoctor = doctors.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header / Search Bar
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book Doctor Consultation',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose a doctor, select your convenient slot & confirm',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  // Search input
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by doctor name or medical specialty...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Specialty Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _specialties.map((spec) {
                        final isSelected = _selectedSpecialty == spec;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSpecialty = spec;
                                if (doctors.isNotEmpty && !doctors.contains(_selectedDoctor)) {
                                  _selectedDoctor = doctors.first;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : AppTheme.border,
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primary.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                spec,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 1. Doctor List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '1. Select Doctor',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${doctors.length} Doctors Available',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final doc = doctors[index];
                  final isSelected = _selectedDoctor?.id == doc.id;
                  return _buildDoctorCard(doc, isSelected);
                },
                childCount: doctors.length,
              ),
            ),
          ),

          // 2. Select Date (Horizontal Calendar Carousel)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: const Text(
                '2. Select Appointment Date',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 80,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _dateOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = _dateOptions[index];
                  final isSelected = _selectedDate == item['date'];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = item['date']!;
                        _selectedTimeSlot = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 74,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['day']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['date']!.split(' ')[0], // e.g. "18"
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            item['dayName']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white70 : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Time Slots (Morning & Evening)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '3. Select Time Slot (15 Mins)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Fast OP Queue',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Morning Slots Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFD97706)),
                          SizedBox(width: 6),
                          Text('Morning Sessions (09:00 AM – 12:30 PM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _morningSlots.map((slot) => _buildSlotChip(slot, state)).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      const Row(
                        children: [
                          Icon(Icons.nightlight_outlined, size: 16, color: Color(0xFF6366F1)),
                          SizedBox(width: 6),
                          Text('Evening Sessions (04:30 PM – 08:00 PM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _eveningSlots.map((slot) => _buildSlotChip(slot, state)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Symptoms & Reason for visit
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: const Text(
                '4. Reason for Consultation / Symptoms',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Symptoms chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickSymptoms.map((symptom) {
                      final isSelected = _reasonController.text == symptom;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _reasonController.text = symptom;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryLight : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
                          ),
                          child: Text(
                            symptom,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Enter specific symptoms or notes for doctor...',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom padding for sticky button
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Confirmation Bar (High converting & frictionless!)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTimeSlot != null ? '$_selectedDate at $_selectedTimeSlot' : 'Select a time slot',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDoctor != null ? 'Fee: ₹${_selectedDoctor!.consultationFee.toInt()} (Pay at clinic)' : 'Select doctor',
                      style: const TextStyle(fontSize: 12, color: AppTheme.secondary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_selectedDoctor != null && _selectedTimeSlot != null)
                    ? () => _handleConfirmBooking(context, state, patient)
                    : null,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                label: const Text('Confirm & Book'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doc, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedDoctor = doc;
              _selectedTimeSlot = null;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryLight,
                      child: const Icon(Icons.person, color: AppTheme.primary, size: 30),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.verified, color: AppTheme.primary, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              doc.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                            ),
                          ),
                          Text(
                            '₹${doc.consultationFee.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doc.qualification} • ${doc.specialty}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 2),
                                Text(
                                  '${doc.rating}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${doc.experienceYears} experience',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotChip(String slot, ClinicStateProvider state) {
    final isBooked = state.appointments.any(
      (a) => a.date == _selectedDate && a.doctorId == _selectedDoctor?.id && a.timeSlot == slot,
    );
    final isSelected = _selectedTimeSlot == slot;

    return InkWell(
      onTap: isBooked
          ? null
          : () {
              setState(() {
                _selectedTimeSlot = slot;
              });
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isBooked
              ? AppTheme.surfaceMuted
              : (isSelected ? AppTheme.primary : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isBooked
                ? AppTheme.border
                : (isSelected ? AppTheme.primary : AppTheme.border),
          ),
        ),
        child: Text(
          slot,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isBooked
                ? AppTheme.textMuted
                : (isSelected ? Colors.white : AppTheme.textPrimary),
            decoration: isBooked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  void _handleConfirmBooking(BuildContext context, ClinicStateProvider state, dynamic patient) {
    final appt = state.bookAppointment(
      patientId: patient.patientId,
      patientName: patient.name,
      patientPhone: patient.mobile,
      doctorId: _selectedDoctor!.id,
      doctorName: _selectedDoctor!.name,
      doctorSpecialty: _selectedDoctor!.specialty,
      date: _selectedDate,
      timeSlot: _selectedTimeSlot!,
      reason: _reasonController.text.trim(),
      createdByType: 'customer',
      fee: _selectedDoctor!.consultationFee,
      isFeePaid: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.secondaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'Appointment Confirmed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Your slot has been reserved with ${_selectedDoctor!.name}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _confirmRow('Token Number', '#${appt.tokenNumber}', isHighlight: true),
                  const Divider(height: 14),
                  _confirmRow('Date & Time', '$_selectedDate at $_selectedTimeSlot'),
                  const Divider(height: 14),
                  _confirmRow('Doctor', _selectedDoctor!.name),
                  const Divider(height: 14),
                  _confirmRow(
                      'Clinic Location',
                      state.settings.address.isNotEmpty
                          ? '${state.clinicName}, ${state.settings.address}'
                          : state.clinicName),
                  const Divider(height: 14),
                  _confirmRow('Consultation Fee', '₹${_selectedDoctor!.consultationFee.toInt()} (Payable at OP counter)'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onBookingSuccess?.call();
                },
                child: const Text('View in My Appointments'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
