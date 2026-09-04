import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/staff_attendance.dart';
import '../../../providers/clinic_state_provider.dart';

class StaffAttendanceTab extends StatelessWidget {
  const StaffAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final user = state.currentUser;
    final staffId = user?.staffId ?? user?.id ?? '';
    final staffName = user?.name ?? 'Staff';

    // Was pinned to a fixed date, so today's check-in never matched and the
    // button stayed on "Check In" all day.
    final myRecord = state.attendanceRecords.cast<StaffAttendance?>().firstWhere(
      (a) => a?.staffId == staffId && a?.date == state.todayKey,
      orElse: () => null,
    );

    final isCheckedIn = myRecord?.checkInTime != null;
    final isCheckedOut = myRecord?.checkOutTime != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.how_to_reg_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Staff Attendance & Time Clock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('Daily check-in / check-out & monthly tally', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Daily Punch Card (Proposal Page 18: Staff self check-in/check-out)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Staff ID: $staffId • ${state.selectedBranch.locality}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCheckedIn ? AppTheme.secondaryLight : AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCheckedIn ? 'PRESENT' : 'NOT CLOCKED IN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCheckedIn ? AppTheme.secondary : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Clock-In Time', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              myRecord?.checkInTime ?? '--:--',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Clock-Out Time', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              myRecord?.checkOutTime ?? '--:--',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: !isCheckedIn
                              ? () {
                                  state.checkInStaff(staffId, staffName);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Clocked in successfully at 08:30 AM')),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.login, size: 18),
                          label: const Text('Check In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isCheckedIn && !isCheckedOut
                              ? () {
                                  state.checkOutStaff(staffId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Clocked out successfully at 05:30 PM')),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Check Out'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly Attendance Report Table (Proposal Page 18: Staff Name, Present, Absent, Leave)
          const Text('Monthly Attendance Summary (August 2026)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Staff Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                      Row(
                        children: [
                          Text('Present  ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.success)),
                          Text('Absent  ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.danger)),
                          Text('Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.warning)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildMonthlyRow('Priya Raman (Reception)', '24', '2', '1'),
                  const Divider(height: 14),
                  _buildMonthlyRow('Muruganandam K (Pharmacy)', '25', '1', '1'),
                  const Divider(height: 14),
                  _buildMonthlyRow('Kavitha S (Staff Nurse)', '22', '3', '2'),
                  const Divider(height: 14),
                  _buildMonthlyRow('Selvaraj P (Admin Staff)', '26', '0', '1'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRow(String name, String present, String absent, String leave) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
        ),
        Row(
          children: [
            SizedBox(width: 45, child: Text(present, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success))),
            SizedBox(width: 45, child: Text(absent, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger))),
            SizedBox(width: 45, child: Text(leave, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning))),
          ],
        ),
      ],
    );
  }
}
