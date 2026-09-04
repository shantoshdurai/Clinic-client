import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pharmacy_item.dart';
import '../../providers/clinic_state_provider.dart';
import '../common/widgets/clinic_app_bar.dart';

class PharmacyInventoryScreen extends StatefulWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  State<PharmacyInventoryScreen> createState() => _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends State<PharmacyInventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);
    final allItems = state.pharmacyItems;
    final lowStock = state.lowStockItems;
    final stockTransactions = state.stockTransactions;

    final filtered = allItems.where((i) {
      final q = _searchController.text.toLowerCase();
      return i.medicineName.toLowerCase().contains(q) ||
          i.genericName.toLowerCase().contains(q) ||
          i.brand.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const ClinicAppBar(
        title: 'Pharmacy & Stock Inventory',
      ),
      body: Column(
        children: [
          // Low Stock Alert Banner (Proposal Page 17)
          if (lowStock.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOW STOCK ALERT (${lowStock.length} Items)',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.danger, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lowStock.map((m) => '${m.medicineName} (${m.currentQuantity} left)').join(' • '),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showStockInDialog(context, state, lowStock.first),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: const Text('Reorder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Medicine Master (${allItems.length})'),
                Tab(text: 'Low Stock (${lowStock.length})'),
                Tab(text: 'Stock Movement Ledger (${stockTransactions.length})'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMedicineMasterTab(context, filtered, state),
                _buildMedicineMasterTab(context, lowStock, state),
                _buildLedgerTab(context, stockTransactions),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStockInDialog(context, state, null),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text('Stock IN (Purchase)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMedicineMasterTab(BuildContext context, List<PharmacyItem> items, ClinicStateProvider state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search medicine by brand or generic name...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchController.clear()))
                  : null,
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No medicine found.', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildMedicineCard(context, item, state);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(BuildContext context, PharmacyItem item, ClinicStateProvider state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.isLowStock ? AppTheme.danger.withValues(alpha: 0.4) : AppTheme.border,
          width: item.isLowStock ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
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
                      Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(item.genericName, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isLowStock ? const Color(0xFFFEE2E2) : AppTheme.secondaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.currentQuantity} Qty',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: item.isLowStock ? AppTheme.danger : AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Batch: ${item.batchNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('Exp: ${item.expiryDate}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('MRP: ₹${item.sellingPrice.toInt()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  Text('Min Stock: ${item.minStockAlertQuantity}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDispenseDialog(context, state, item),
                  icon: const Icon(Icons.arrow_downward, size: 14, color: AppTheme.danger),
                  label: const Text('Dispense / Stock OUT', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showStockInDialog(context, state, item),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Stock IN', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerTab(BuildContext context, List<StockTransaction> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No stock movements recorded yet.', style: TextStyle(color: AppTheme.textMuted)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = list[i];
        final isStockIn = t.type == StockTransactionType.stockIn;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isStockIn ? AppTheme.secondaryLight : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isStockIn ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isStockIn ? AppTheme.secondary : AppTheme.danger,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${t.reason} • by ${t.performedBy}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Text(
                '${isStockIn ? "+" : "-"}${t.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isStockIn ? AppTheme.secondary : AppTheme.danger,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStockInDialog(BuildContext context, ClinicStateProvider state, PharmacyItem? initialItem) {
    PharmacyItem selected = initialItem ?? state.pharmacyItems.first;
    final qtyController = TextEditingController(text: '100');
    final batchController = TextEditingController(text: 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final expController = TextEditingController(text: '12/2028');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Stock IN (Purchase)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<PharmacyItem>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Medicine Item'),
                items: state.pharmacyItems.map((p) => DropdownMenuItem(value: p, child: Text(p.medicineName))).toList(),
                onChanged: (v) => selected = v!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity Added', prefixIcon: Icon(Icons.add_box)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: batchController,
                decoration: const InputDecoration(labelText: 'Batch Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expController,
                decoration: const InputDecoration(labelText: 'Expiry Date (MM/YYYY)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 100;
              state.addStockIn(
                pharmacyItemId: selected.id,
                quantity: qty,
                batchNumber: batchController.text,
                expiryDate: expController.text,
                purchasePrice: selected.purchasePrice,
                sellingPrice: selected.sellingPrice,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $qty units to ${selected.medicineName}')),
              );
            },
            child: const Text('Confirm Stock IN'),
          ),
        ],
      ),
    );
  }

  void _showDispenseDialog(BuildContext context, ClinicStateProvider state, PharmacyItem item) {
    final qtyController = TextEditingController(text: '10');
    final reasonController = TextEditingController(text: 'Patient Dispensing (Rx)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Dispense ${item.medicineName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock Available: ${item.currentQuantity} units', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity to Dispense', prefixIcon: Icon(Icons.remove_circle_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Dispensing Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 1;
              state.dispenseMedicine(
                pharmacyItemId: item.id,
                quantity: qty,
                reason: reasonController.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dispensed $qty units of ${item.medicineName}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Confirm Dispense'),
          ),
        ],
      ),
    );
  }
}
