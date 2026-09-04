import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../providers/clinic_state_provider.dart';

class CustomerHistoryTab extends StatefulWidget {
  final bool initiallyOpenBooking;
  final Function(int)? onTabChange;

  const CustomerHistoryTab({
    super.key,
    this.initiallyOpenBooking = false,
    this.onTabChange,
  });

  @override
  State<CustomerHistoryTab> createState() => _CustomerHistoryTabState();
}

class _CustomerHistoryTabState extends State<CustomerHistoryTab> {
  String _selectedFilter = 'Upcoming';
  late bool _showBooking;

  // Booking form state
  String _selectedDate = '18 Aug 2026';
  String? _selectedTimeSlot;
  final TextEditingController _reasonController = TextEditingController(text: 'General consultation');

  final List<Map<String, String>> _dateOptions = [
    {'label': 'Today', 'date': '18 Aug 2026', 'short': '18', 'day': 'Tue'},
    {'label': 'Wed', 'date': '19 Aug 2026', 'short': '19', 'day': 'Wed'},
    {'label': 'Thu', 'date': '20 Aug 2026', 'short': '20', 'day': 'Thu'},
    {'label': 'Fri', 'date': '21 Aug 2026', 'short': '21', 'day': 'Fri'},
    {'label': 'Sat', 'date': '22 Aug 2026', 'short': '22', 'day': 'Sat'},
    {'label': 'Mon', 'date': '24 Aug 2026', 'short': '24', 'day': 'Mon'},
  ];

  final List<String> _morningSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM',
  ];

  final List<String> _eveningSlots = [
    '05:00 PM', '05:30 PM', '06:00 PM', '06:30 PM', '07:00 PM', '07:30 PM', '08:00 PM',
  ];

  final List<String> _quickReasons = [
    'General consultation',
    'Fever & Cold',
    'Headache / Body ache',
    'Blood sugar review',
    'BP Checkup',
  ];

  @override
  void initState() {
    super.initState();
    _showBooking = widget.initiallyOpenBooking;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleConfirmBooking(ClinicStateProvider state, dynamic patient, dynamic doctor) {
    final appt = state.bookAppointment(
      patientId: patient.patientId,
      patientName: patient.name,
      patientPhone: patient.mobile,
      doctorId: doctor.id,
      doctorName: doctor.name,
      doctorSpecialty: doctor.specialty,
      date: _selectedDate,
      timeSlot: _selectedTimeSlot!,
      reason: _reasonController.text.trim(),
      fee: doctor.consultationFee,
    );

    setState(() {
      _showBooking = false;
      _selectedTimeSlot = null;
      _selectedFilter = 'Upcoming';
    });

    // Confirmation Modal informing that clinic will contact them shortly
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
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryDark, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Slot Request Received!',
              style: AppTheme.serifTitle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We have received your appointment request for $_selectedDate at ${appt.timeSlot}.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.textPrimary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, size: 20, color: Color(0xFFB45309)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Our clinic reception will call you shortly on +91 ${patient.mobile} to confirm your slot.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Assigned Queue Token', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                  Text('Token #${appt.tokenNumber}', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Done & View Appointments',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final user = state.currentUser;
    final patientId = user?.patientId ?? 'PAT-000123';

    var appts = state.appointments.where((a) => a.patientId == patientId).toList();
    if (_selectedFilter == 'Upcoming') {
      appts = appts.where((a) =>
          a.status != AppointmentStatus.completed &&
          a.status != AppointmentStatus.cancelled).toList();
    } else if (_selectedFilter == 'Past') {
      appts = appts.where((a) => a.status == AppointmentStatus.completed).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header with Editorial Serif Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Appointments',
                    style: AppTheme.serifHero(fontSize: 28),
                  ),
                  InkWell(
                    onTap: () => setState(() => _showBooking = !_showBooking),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: !_showBooking
                            ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                            : null,
                        color: _showBooking ? AppTheme.primaryLight : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !_showBooking ? AppTheme.glowGreenShadow : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showBooking ? Icons.close_rounded : Icons.add_rounded,
                            size: 16,
                            color: _showBooking ? AppTheme.primaryDark : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showBooking ? 'Close' : 'New',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _showBooking ? AppTheme.primaryDark : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Booking Drawer / Card
          if (_showBooking)
            SliverToBoxAdapter(
              child: _buildBookingForm(context, state),
            ),

          // Filter Segmented Control
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: ['Upcoming', 'Past', 'All'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = filter),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.textPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.textPrimary : AppTheme.border,
                          ),
                          boxShadow: isSelected ? AppTheme.cardShadow : null,
                        ),
                        child: Text(
                          filter,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Appointment Records
          if (appts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_busy_rounded, size: 36, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No ${_selectedFilter.toLowerCase()} appointments',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "+ New" above to book your consultation slot.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildAppointmentCard(appts[i], state),
                  childCount: appts.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildBookingForm(BuildContext context, ClinicStateProvider state) {
    final user = state.currentUser;
    final patient = state.patients.firstWhere(
      (p) => p.patientId == (user?.patientId ?? 'PAT-000123'),
      orElse: () => state.patients.first,
    );
    final doctor = state.doctors.first;
    final isSlotSelected = _selectedTimeSlot != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                'Book Clinic Visit',
                style: AppTheme.serifSubtitle(fontSize: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '15-Min OP Slot',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Selector
          Text(
            'Select Date',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dateOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = _dateOptions[i];
                final isSelected = _selectedDate == d['date'];
                return InkWell(
                  onTap: () => setState(() {
                    _selectedDate = d['date']!;
                    _selectedTimeSlot = null;
                  }),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: isSelected ? null : AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSelected ? AppTheme.glowGreenShadow : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          d['day']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white70 : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d['short']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Aug',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
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
          const SizedBox(height: 20),

          // Time Slots
          Text(
            'Select Time Slot',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),

          Text('Morning Sessions (09:00 AM – 12:30 PM)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _morningSlots.map((slot) => _buildSlotChip(slot, state)).toList(),
          ),

          const SizedBox(height: 12),
          Text('Evening Sessions (05:00 PM – 08:00 PM)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _eveningSlots.map((slot) => _buildSlotChip(slot, state)).toList(),
          ),

          const SizedBox(height: 18),

          // Quick Reason Chips
          Text(
            'Reason for Visit',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickReasons.map((r) {
              final isSelected = _reasonController.text == r;
              return InkWell(
                onTap: () => setState(() => _reasonController.text = r),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryLight : AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
                  ),
                  child: Text(
                    r,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _reasonController,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter specific symptoms or notes...',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceMuted,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Glow-Up Confirm Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: isSlotSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSlotSelected ? null : AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSlotSelected ? AppTheme.glowGreenShadow : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSlotSelected
                    ? () => _handleConfirmBooking(state, patient, doctor)
                    : null,
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Text(
                    isSlotSelected
                        ? 'Request Slot  •  $_selectedDate at $_selectedTimeSlot'
                        : 'Select a time slot above',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSlotSelected ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotChip(String slot, ClinicStateProvider state) {
    final isBooked = state.appointments.any(
      (a) => a.date == _selectedDate && a.timeSlot == slot && a.status != AppointmentStatus.cancelled,
    );
    final isSelected = _selectedTimeSlot == slot;

    return InkWell(
      onTap: isBooked ? null : () => setState(() => _selectedTimeSlot = slot),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isBooked
              ? AppTheme.surfaceMuted
              : (isSelected ? AppTheme.primary : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isBooked ? AppTheme.border : (isSelected ? AppTheme.primary : AppTheme.border),
          ),
        ),
        child: Text(
          slot,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isBooked ? AppTheme.textMuted : (isSelected ? Colors.white : AppTheme.textPrimary),
            decoration: isBooked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appt, ClinicStateProvider state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.doctorName,
                      style: AppTheme.serifSubtitle(fontSize: 18),
                    ),
                    Text(
                      appt.doctorSpecialty,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Token #${appt.tokenNumber}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      '${appt.date} • ${appt.timeSlot}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Slot Reserved',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (appt.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              appt.reason,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
