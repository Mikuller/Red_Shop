import 'enums.dart';
import 'model_utils.dart';

class SaleDraftItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const SaleDraftItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
}

class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double costPrice;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      quantity: readInt(map['quantity']),
      unitPrice: readDouble(map['unitPrice'] ?? map['priceAtSale']),
      costPrice: readDouble(map['costPrice']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'costPrice': costPrice,
      'lineTotal': lineTotal,
      'lineProfit': lineProfit,
    };
  }

  double get lineTotal => quantity * unitPrice;

  double get lineProfit => quantity * (unitPrice - costPrice);
}

class SaleRecord {
  final String id;
  final List<SaleItem> items;
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final SaleChannel channel;
  final DateTime createdAt;
  final String processedByUid;
  final String processedByName;

  const SaleRecord({
    required this.id,
    required this.items,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.channel,
    required this.createdAt,
    required this.processedByUid,
    required this.processedByName,
  });

  factory SaleRecord.fromMap(Map<String, dynamic> map, String id) {
    final items = (map['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SaleItem.fromMap)
        .toList();
    final totalRevenue = readDouble(map['totalRevenue'] ?? map['total']);
    final totalCost = readDouble(
      map['totalCost'] ??
          items.fold<double>(
            0,
            (total, item) => total + (item.costPrice * item.quantity),
          ),
    );

    return SaleRecord(
      id: id,
      items: items,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      grossProfit: readDouble(
        map['grossProfit'] ?? (totalRevenue - totalCost),
      ),
      channel: readSaleChannel(map['channel']),
      createdAt: readDateTime(map['createdAt'] ?? map['timestamp']),
      processedByUid:
          map['processedByUid']?.toString() ?? map['clerkId']?.toString() ?? '',
      processedByName: map['processedByName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'grossProfit': grossProfit,
      'channel': channel.name,
      'createdAt': createdAt,
      'processedByUid': processedByUid,
      'processedByName': processedByName,
    };
  }

  bool get isInstantSale => channel == SaleChannel.instant;

  String get primaryName => items.isEmpty ? '' : items.first.productName;
}
