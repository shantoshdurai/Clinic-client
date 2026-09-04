enum StockTransactionType {
  stockIn,
  stockOut,
  adjustment,
}

class PharmacyItem {
  final String id;
  final String medicineName;
  final String genericName;
  final String brand;
  final String batchNumber;
  final String expiryDate; // MM/YYYY
  final double purchasePrice;
  final double sellingPrice;
  final int currentQuantity;
  final int minStockAlertQuantity;
  final String branchId;

  PharmacyItem({
    required this.id,
    required this.medicineName,
    required this.genericName,
    required this.brand,
    required this.batchNumber,
    required this.expiryDate,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentQuantity,
    this.minStockAlertQuantity = 25,
    required this.branchId,
  });

  bool get isLowStock => currentQuantity <= minStockAlertQuantity;

  PharmacyItem copyWith({
    String? id,
    String? medicineName,
    String? genericName,
    String? brand,
    String? batchNumber,
    String? expiryDate,
    double? purchasePrice,
    double? sellingPrice,
    int? currentQuantity,
    int? minStockAlertQuantity,
    String? branchId,
  }) {
    return PharmacyItem(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      genericName: genericName ?? this.genericName,
      brand: brand ?? this.brand,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minStockAlertQuantity: minStockAlertQuantity ?? this.minStockAlertQuantity,
      branchId: branchId ?? this.branchId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicineName': medicineName,
        'genericName': genericName,
        'brand': brand,
        'batchNumber': batchNumber,
        'expiryDate': expiryDate,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'currentQuantity': currentQuantity,
        'minStockAlertQuantity': minStockAlertQuantity,
        'branchId': branchId,
      };

  factory PharmacyItem.fromMap(Map<String, dynamic> map) {
    return PharmacyItem(
      id: map['id'] as String? ?? '',
      medicineName: map['medicineName'] as String? ?? '',
      genericName: map['genericName'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      batchNumber: map['batchNumber'] as String? ?? '',
      expiryDate: map['expiryDate'] as String? ?? '',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      currentQuantity: (map['currentQuantity'] as num?)?.toInt() ?? 0,
      minStockAlertQuantity: (map['minStockAlertQuantity'] as num?)?.toInt() ?? 25,
      branchId: map['branchId'] as String? ?? 'main_clinic',
    );
  }
}

class StockTransaction {
  final String id;
  final String pharmacyItemId;
  final String medicineName;
  final StockTransactionType type;
  final int quantity;
  final String reason;
  final String performedBy;
  final DateTime timestamp;

  StockTransaction({
    required this.id,
    required this.pharmacyItemId,
    required this.medicineName,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.performedBy,
    required this.timestamp,
  });
}
