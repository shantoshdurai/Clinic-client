import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/payment.dart';
import '../../providers/clinic_state_provider.dart';
import '../common/widgets/clinic_app_bar.dart';

class BillingReportsScreen extends StatefulWidget {
  final bool showAppBar;
  final bool isDoctor;

  const BillingReportsScreen({
    super.key,
    this.showAppBar = false,
    this.isDoctor = false,
  });

  @override
  State<BillingReportsScreen> createState() => _BillingReportsScreenState();
}

class _BillingReportsScreenState extends State<BillingReportsScreen> {
  String _selectedFilter = 'Today';

  void _showTransferCashDialog(
    BuildContext context,
    ClinicStateProvider state,
    double availableCashInHand,
  ) {
    if (availableCashInHand <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No physical cash available in hand to transfer.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cashCtrl = TextEditingController(text: availableCashInHand.toInt().toString());
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final typedAmount = double.tryParse(cashCtrl.text.trim()) ?? 0.0;
          final remainingWithNurse = (availableCashInHand - typedAmount).clamp(0.0, 999999.0);

          return Container(
            padding: EdgeInsets.only(
              top: 22,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transfer Cash to Doctor', style: AppTheme.serifTitle(fontSize: 18)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Physical Cash in Hand: ₹${availableCashInHand.toInt()}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: cashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  onChanged: (val) {
                    final v = double.tryParse(val.trim()) ?? 0.0;
                    setDlgState(() {
                      if (v <= 0) {
                        errorText = 'Enter an amount greater than ₹0';
                      } else if (v > availableCashInHand) {
                        errorText = 'Cannot exceed Cash in Hand (₹${availableCashInHand.toInt()})';
                      } else {
                        errorText = null;
                      }
                    });
                  },
                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                  decoration: InputDecoration(
                    labelText: 'Transfer Amount (₹)',
                    errorText: errorText,
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800),
                    suffixIcon: TextButton(
                      onPressed: () {
                        setDlgState(() {
                          cashCtrl.text = availableCashInHand.toInt().toString();
                          errorText = null;
                        });
                      },
                      child: const Text('All Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Remaining with Nurse:',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      Text('₹${remainingWithNurse.toInt()}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: remainingWithNurse > 0 ? AppTheme.warning : AppTheme.success)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (typedAmount <= 0 || typedAmount > availableCashInHand)
                        ? null
                        : () {
                            state.recordCashHandover(
                              amount: typedAmount,
                              handedOverByName:
                                  state.currentUser?.name ?? 'Reception Desk',
                              receivedByName: state.primaryDoctorName,
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ ₹${typedAmount.toInt()} transferred to Doctor!'),
                                backgroundColor: AppTheme.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                    label: Text(
                      'Confirm Transfer (₹${typedAmount.toInt()})',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showChangePaymentModeDialog(BuildContext context, ClinicStateProvider state, Payment payment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Payment Method', style: AppTheme.serifTitle(fontSize: 18)),
            const SizedBox(height: 6),
            Text('Patient: ${payment.patientName} • Amount: ₹${payment.amountPaid.toInt()}',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.payments_outlined, color: AppTheme.success),
              ),
              title: const Text('Cash (Physical Note)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Counted in Nurse Cash in Hand'),
              trailing: payment.nursePaymentMode == PaymentMode.cash
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.success)
                  : null,
              onTap: () {
                state.updatePaymentMode(payment.id, PaymentMode.cash);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched ${payment.patientName} to Cash'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2563EB)),
              ),
              title: const Text('GPay / PhonePe / UPI', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Direct Bank QR Transfer'),
              trailing: payment.nursePaymentMode == PaymentMode.upi
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB))
                  : null,
              onTap: () {
                state.updatePaymentMode(payment.id, PaymentMode.upi);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched ${payment.patientName} to GPay / UPI'),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final now = DateTime.now();

    // Filter payments based on selected filter
    final filteredPayments = state.payments.where((p) {
      if (_selectedFilter == 'Today') {
        return p.paymentDate.year == now.year && p.paymentDate.month == now.month && p.paymentDate.day == now.day;
      } else if (_selectedFilter == 'Yesterday') {
        final yesterday = now.subtract(const Duration(days: 1));
        return p.paymentDate.year == yesterday.year && p.paymentDate.month == yesterday.month && p.paymentDate.day == yesterday.day;
      } else if (_selectedFilter == 'This Week') {
        final weekAgo = now.subtract(const Duration(days: 7));
        return p.paymentDate.isAfter(weekAgo);
      } else if (_selectedFilter == 'This Month') {
        return p.paymentDate.year == now.year && p.paymentDate.month == now.month;
      }
      return true;
    }).toList();

    final totalRevenue = filteredPayments.fold(0.0, (sum, p) => sum + p.amountPaid);
    final nurseCollected = filteredPayments.fold(0.0, (sum, p) => sum + p.paidToNurse);
    final doctorCollected = filteredPayments.fold(0.0, (sum, p) => sum + p.paidToDoctor);
    final pendingDues = filteredPayments.fold(0.0, (sum, p) => sum + p.balance);

    final totalNurseCash = filteredPayments
        .where((p) => p.nursePaymentMode == PaymentMode.cash)
        .fold(0.0, (sum, p) => sum + p.paidToNurse);
    final nurseUpi = filteredPayments
        .where((p) => p.nursePaymentMode == PaymentMode.upi)
        .fold(0.0, (sum, p) => sum + p.paidToNurse);
    final doctorUpi = filteredPayments
        .where((p) => p.doctorPaymentMode == PaymentMode.upi)
        .fold(0.0, (sum, p) => sum + p.paidToDoctor);

    final todayHandovers = state.getTodayHandovers();
    final totalHandedOverCash = state.getTodayTotalHandedOverCash();
    final nurseRemainingCash = (totalNurseCash - totalHandedOverCash).clamp(0.0, 999999.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: widget.showAppBar
          ? ClinicAppBar(title: widget.isDoctor ? 'Clinic Financial Audit' : 'Reception Collections & Closing')
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Today', 'Yesterday', 'This Week', 'This Month'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // 👩‍⚕️ NURSE RECEPTION VIEW
            // ==========================================
            if (!widget.isDoctor) ...[
              // Total Reception Collections Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_selectedFilter Counter Collections',
                            style: const TextStyle(fontSize: 13.5, color: Colors.white70, fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                          child: Text(_selectedFilter,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${nurseCollected.toInt()}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatSubItem('Cash Collected', '₹${totalNurseCash.toInt()}', Colors.white),
                        Container(width: 1, height: 22, color: Colors.white24),
                        _buildStatSubItem('GPay / UPI', '₹${nurseUpi.toInt()}', const Color(0xFF99F6E4)),
                        Container(width: 1, height: 22, color: Colors.white24),
                        _buildStatSubItem('Patients Paid', '${filteredPayments.length}', const Color(0xFFFDE68A)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cash Transfer Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: totalHandedOverCash > 0 && nurseRemainingCash == 0
                        ? AppTheme.success
                        : AppTheme.border,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cash Handover to Doctor',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        if (totalHandedOverCash > 0 && nurseRemainingCash == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(6)),
                            child: const Text('All Handed Over ✅',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Physical Cash in Hand', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                const SizedBox(height: 4),
                                Text('₹${nurseRemainingCash.toInt()}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: nurseRemainingCash > 0 ? AppTheme.textPrimary : AppTheme.success)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Handed Over', style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF))),
                                const SizedBox(height: 4),
                                Text('₹${totalHandedOverCash.toInt()}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Action Button or Summary
                    if (nurseRemainingCash > 0) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _showTransferCashDialog(context, state, nurseRemainingCash),
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                          label: Text(
                            'Transfer Cash to Doctor (₹${nurseRemainingCash.toInt()})',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ] else if (totalHandedOverCash > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '✅ ₹${totalHandedOverCash.toInt()} total cash received by Dr. Raj',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success),
                            ),
                            InkWell(
                              onTap: () => state.resetCashHandover(),
                              child: const Text('Undo',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'No cash collected yet to transfer.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],

                    // Previous handovers log
                    if (todayHandovers.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Text('Today\'s Handovers (${todayHandovers.length})',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      ...todayHandovers.map((h) {
                        final timeStr = DateFormat('hh:mm a').format(h.settledAt);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('• ₹${h.nurseCash.toInt()} handed over at $timeStr',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textPrimary)),
                              InkWell(
                                onTap: () => state.deleteCashHandover(h.id),
                                child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.danger),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nurse Today's Entries
              if (filteredPayments.isNotEmpty) ...[
                Card(
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
                        Text('$_selectedFilter Patient Token Entries (${filteredPayments.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                        const SizedBox(height: 12),
                        ...filteredPayments.map((p) {
                          final isCash = p.nursePaymentMode == PaymentMode.cash;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.patientName,
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.billNumber} • ${isCash ? '💵 Cash' : '📱 GPay/UPI'}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${p.amountPaid.toInt()}',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            // ==========================================
            // 🩺 DOCTOR CABIN VIEW
            // ==========================================
            if (widget.isDoctor) ...[
              // Total Clinic Revenue Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_selectedFilter Total Revenue',
                            style: const TextStyle(fontSize: 13.5, color: Colors.white70, fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                          child: Text(_selectedFilter,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${totalRevenue.toInt()}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatSubItem('Nurse Counter', '₹${nurseCollected.toInt()}', Colors.white),
                        Container(width: 1, height: 22, color: Colors.white24),
                        _buildStatSubItem('Doctor Cabin', '₹${doctorCollected.toInt()}', const Color(0xFF99F6E4)),
                        Container(width: 1, height: 22, color: Colors.white24),
                        _buildStatSubItem('Pending Dues', '₹${pendingDues.toInt()}', const Color(0xFFFCA5A5)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Collections Channel Breakdown
              Card(
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
                      Text('$_selectedFilter Collections Summary',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                      const SizedBox(height: 12),
                      _buildDoctorSummaryRow(
                        'Cash Received from Nurse',
                        '₹${totalHandedOverCash.toInt()}',
                        Icons.payments_outlined,
                        AppTheme.success,
                        subtitle: nurseRemainingCash > 0
                            ? 'Pending with Nurse: ₹${nurseRemainingCash.toInt()}'
                            : (totalHandedOverCash > 0 ? 'All Cash Received ✅' : 'No Cash Pending'),
                      ),
                      const Divider(height: 14),
                      _buildDoctorSummaryRow(
                        'Nurse Desk - GPay / UPI',
                        '₹${nurseUpi.toInt()}',
                        Icons.qr_code_2_rounded,
                        const Color(0xFF2563EB),
                        subtitle: 'Auto bank account collection',
                      ),
                      const Divider(height: 14),
                      _buildDoctorSummaryRow(
                        'Doctor Cabin Collections',
                        '₹${doctorUpi.toInt()}',
                        Icons.medical_services_outlined,
                        AppTheme.secondary,
                        subtitle: 'In-cabin procedures / UPI',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Doctor Patient Transactions (With 1-Tap Payment Mode Switcher)
              if (filteredPayments.isNotEmpty) ...[
                Card(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$_selectedFilter Transactions (${filteredPayments.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                            Text('Tap mode to change',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...filteredPayments.map((p) {
                          final isCash = p.nursePaymentMode == PaymentMode.cash;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.patientName,
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.billNumber} • By ${p.collectedByName}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 1-Tap Payment Mode Switcher (Doctor can change Cash <-> GPay)
                                InkWell(
                                  onTap: () => _showChangePaymentModeDialog(context, state, p),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCash ? AppTheme.successLight : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isCash ? '💵 Cash' : '📱 GPay',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isCash ? AppTheme.success : const Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(Icons.arrow_drop_down,
                                            size: 14, color: isCash ? AppTheme.success : const Color(0xFF2563EB)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${p.amountPaid.toInt()}',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSubItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildDoctorSummaryRow(String title, String amount, IconData icon, Color color, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (subtitle != null)
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
        ],
      ),
    );
  }
}
