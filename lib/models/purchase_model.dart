import 'model_utils.dart';

class PurchaseItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitCost;

  const PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      quantity: readInt(map['quantity']),
      unitCost: readDouble(map['unitCost']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitCost': unitCost,
      'lineTotal': lineTotal,
    };
  }

  double get lineTotal => quantity * unitCost;
}

class PurchaseRecord {
  final String id;
  final String supplier;
  final String note;
  final List<PurchaseItem> items;
  final double totalCost;
  final DateTime createdAt;
  final String createdByUid;
  final String createdByName;

  const PurchaseRecord({
    required this.id,
    required this.supplier,
    required this.note,
    required this.items,
    required this.totalCost,
    required this.createdAt,
    required this.createdByUid,
    required this.createdByName,
  });

  factory PurchaseRecord.fromMap(Map<String, dynamic> map, String id) {
    final items = (map['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PurchaseItem.fromMap)
        .toList();

    return PurchaseRecord(
      id: id,
      supplier: map['supplier']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      items: items,
      totalCost: readDouble(
        map['totalCost'] ??
            items.fold<double>(0, (total, item) => total + item.lineTotal),
      ),
      createdAt: readDateTime(map['createdAt']),
      createdByUid: map['createdByUid']?.toString() ?? '',
      createdByName: map['createdByName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplier': supplier,
      'note': note,
      'items': items.map((item) => item.toMap()).toList(),
      'totalCost': totalCost,
      'createdAt': createdAt,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
    };
  }
}
