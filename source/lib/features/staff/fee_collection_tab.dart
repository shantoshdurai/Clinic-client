import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/op_visit.dart';
import '../../../models/payment.dart';
import '../../../providers/clinic_state_provider.dart';

class FeeCollectionTab extends StatefulWidget {
  const FeeCollectionTab({super.key});

  @override
  State<FeeCollectionTab> createState() => _FeeCollectionTabState();
}

class _FeeCollectionTabState extends State<FeeCollectionTab> {
  OpVisit? _selectedVisit;
  final TextEditingController _amountToCollectController = TextEditingController(text: '500');
  final TextEditingController _notesController = TextEditingController();
  PaymentMode _paymentMode = PaymentMode.cash;

  @override
  void dispose() {
    _amountToCollectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final visits = state.opVisits;
    final payments = state.payments;

    if (_selectedVisit == null && visits.isNotEmpty) {
      _selectedVisit = visits.first;
      _amountToCollectController.text = _selectedVisit!.balance.toInt().toString();
    }

    final double balance = _selectedVisit?.balance ?? 0.0;
    final double totalBill = _selectedVisit?.totalBill ?? 500.0;
    final double alreadyPaid = _selectedVisit?.amountPaid ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
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
                  Text('Desk Billing & Settlement', style: AppTheme.serifTitle(fontSize: 22)),
                  Text('Live sync with Doctor Cabin extra charges & receipts',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Live Desk',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800, color: AppTheme.primaryDark, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Billing Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select OP Patient from Queue',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<OpVisit>(
                  initialValue: _selectedVisit,
                  isExpanded: true,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.person_search_rounded)),
                  items: visits.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text(
                        'Token #${v.tokenNumber} - ${v.patientName} (${v.paymentStatus.label})',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedVisit = val;
                      if (val != null) {
                        _amountToCollectController.text = val.balance.toInt().toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                if (_selectedVisit != null) ...[
                  // Itemized Bill Breakdown
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Itemized Clinical Bill Breakdown:',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('• Doctor Consultation Fee (${_selectedVisit!.doctorName})',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
                            Text('₹${_selectedVisit!.consultationFee.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                        if (_selectedVisit!.procedureCharges.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ..._selectedVisit!.procedureCharges.map((p) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('• ${p.title} (Added by ${p.addedBy})',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5, color: AppTheme.primaryDark)),
                                    Text('+ ₹${p.amount.toInt()}',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppTheme.primaryDark)),
                                  ],
                                ),
                              )),
                        ],
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Bill Amount',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800, fontSize: 13.5)),
                            Text('₹${totalBill.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Already Paid (Nurse/Doctor)',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5, color: AppTheme.success)),
                            Text('- ₹${alreadyPaid.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.success)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: balance > 0 ? AppTheme.warningLight : AppTheme.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                balance > 0 ? 'Remaining Due / Balance to Collect:' : 'Status: Fully Paid & Settled',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: balance > 0 ? AppTheme.warning : AppTheme.success,
                                ),
                              ),
                              Text(
                                '₹${balance.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: balance > 0 ? AppTheme.danger : AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Settle / Collect Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountToCollectController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount to Collect Now (₹)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Text('Payment Mode',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildModeChip(PaymentMode.cash, 'Cash', Icons.payments_outlined),
                    const SizedBox(width: 8),
                    _buildModeChip(PaymentMode.upi, 'UPI / GPay', Icons.qr_code_scanner_rounded),
                    const SizedBox(width: 8),
                    _buildModeChip(PaymentMode.card, 'Card / POS', Icons.credit_card_rounded),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Reference (Optional)',
                    hintText: 'e.g. Balance settled before departure',
                    prefixIcon: Icon(Icons.receipt_outlined),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _selectedVisit != null
                        ? () => _handleCollectPayment(state)
                        : null,
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: Text(
                      balance > 0
                          ? 'Collect Balance ₹${double.tryParse(_amountToCollectController.text)?.toInt() ?? balance.toInt()} & Issue Receipt'
                          : 'Update Bill & Settle',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Receipts List
          Text('Today\'s Payment Receipts & Audit Trail', style: AppTheme.serifSubtitle(fontSize: 18)),
          const SizedBox(height: 12),

          if (payments.isEmpty)
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
                  const Icon(Icons.receipt_long_outlined, size: 36, color: AppTheme.textMuted),
                  const SizedBox(height: 8),
                  Text('No payment receipts recorded yet today.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = payments[index];
                final isSettled = p.balance <= 0;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSettled ? AppTheme.border : AppTheme.warning.withAlpha(80)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSettled ? AppTheme.primaryLight : AppTheme.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: isSettled ? AppTheme.primaryDark : AppTheme.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p.patientName} (${p.billNumber})',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppTheme.textPrimary)),
                                Text('Phone: ${p.patientPhone.isNotEmpty ? p.patientPhone : "N/A"}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${p.amountPaid.toInt()} Paid',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppTheme.primaryDark)),
                            if (p.balance > 0)
                              Text('Due: ₹${p.balance.toInt()}',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: AppTheme.danger,
                                      fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nurse: ₹${p.paidToNurse.toInt()} (${p.nursePaymentMode.label})',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          if (p.paidToDoctor > 0)
                            Text(
                              'Doctor: ₹${p.paidToDoctor.toInt()} (${p.doctorPaymentMode.label})',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.secondary),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSettled ? AppTheme.successLight : AppTheme.warningLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.status.label,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSettled ? AppTheme.success : AppTheme.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(PaymentMode mode, String label, IconData icon) {
    final isSelected = _paymentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLight : AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCollectPayment(ClinicStateProvider state) {
    final amount = double.tryParse(_amountToCollectController.text) ?? 0.0;
    if (amount <= 0 && _selectedVisit!.balance > 0) return;

    final payment = state.recordStaffPayment(
      appointmentId: _selectedVisit!.id,
      patientId: _selectedVisit!.patientId,
      patientName: _selectedVisit!.patientName,
      consultationFee: _selectedVisit!.consultationFee,
      amountPaid: amount,
      paymentMode: _paymentMode,
      notes: _notesController.text.trim(),
    );

    setState(() {
      _selectedVisit = state.opVisits.firstWhere((v) => v.id == _selectedVisit!.id);
      _amountToCollectController.text = _selectedVisit!.balance.toInt().toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Receipt ${payment.billNumber} updated: ₹${amount.toInt()} collected via ${_paymentMode.label}'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
