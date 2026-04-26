import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, clerk }

enum ExpenseKind { operating, withdrawal }

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _readDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.now();
}

UserRole _readRole(dynamic value) {
  return value == 'owner' ? UserRole.owner : UserRole.clerk;
}

ExpenseKind _readExpenseKind(dynamic value, String category) {
  if (value == 'withdrawal') {
    return ExpenseKind.withdrawal;
  }

  if (category.toLowerCase().contains('withdraw')) {
    return ExpenseKind.withdrawal;
  }

  return ExpenseKind.operating;
}

String userRoleLabel(UserRole role) {
  return role == UserRole.owner ? 'Owner' : 'Clerk';
}

String expenseKindLabel(ExpenseKind kind) {
  return kind == ExpenseKind.operating ? 'Operating' : 'Withdrawal';
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool active;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.active,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: _readRole(map['role']),
      active: map['active'] is bool ? map['active'] as bool : true,
      createdAt: _readDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'active': active,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    bool? active,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String category;
  final String sku;
  final String description;
  final String imageUrl;
  final double suggestedSellingPrice;
  final double averageCost;
  final int stock;
  final int lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.description,
    required this.imageUrl,
    required this.suggestedSellingPrice,
    required this.averageCost,
    required this.stock,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      sku: map['sku']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      suggestedSellingPrice: _readDouble(
        map['suggestedSellingPrice'] ?? map['price'],
      ),
      averageCost: _readDouble(map['averageCost'] ?? map['purchasePrice']),
      stock: _readInt(map['stock']),
      lowStockThreshold: _readInt(map['lowStockThreshold'] ?? 3),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'sku': sku,
      'description': description,
      'imageUrl': imageUrl,
      'suggestedSellingPrice': suggestedSellingPrice,
      'averageCost': averageCost,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? sku,
    String? description,
    String? imageUrl,
    double? suggestedSellingPrice,
    double? averageCost,
    int? stock,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      suggestedSellingPrice:
          suggestedSellingPrice ?? this.suggestedSellingPrice,
      averageCost: averageCost ?? this.averageCost,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get marginPerUnit => suggestedSellingPrice - averageCost;

  bool get isLowStock => stock <= lowStockThreshold;
}

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
      quantity: _readInt(map['quantity']),
      unitCost: _readDouble(map['unitCost']),
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
      totalCost: _readDouble(
        map['totalCost'] ??
            items.fold<double>(0, (total, item) => total + item.lineTotal),
      ),
      createdAt: _readDateTime(map['createdAt']),
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
      quantity: _readInt(map['quantity']),
      unitPrice: _readDouble(map['unitPrice'] ?? map['priceAtSale']),
      costPrice: _readDouble(map['costPrice']),
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
  final DateTime createdAt;
  final String processedByUid;
  final String processedByName;

  const SaleRecord({
    required this.id,
    required this.items,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.createdAt,
    required this.processedByUid,
    required this.processedByName,
  });

  factory SaleRecord.fromMap(Map<String, dynamic> map, String id) {
    final items = (map['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SaleItem.fromMap)
        .toList();
    final totalRevenue = _readDouble(map['totalRevenue'] ?? map['total']);
    final totalCost = _readDouble(
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
      grossProfit: _readDouble(
        map['grossProfit'] ?? (totalRevenue - totalCost),
      ),
      createdAt: _readDateTime(map['createdAt'] ?? map['timestamp']),
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
      'createdAt': createdAt,
      'processedByUid': processedByUid,
      'processedByName': processedByName,
    };
  }
}

class ExpenseRecord {
  final String id;
  final String description;
  final String category;
  final double amount;
  final ExpenseKind kind;
  final DateTime createdAt;
  final String createdByUid;
  final String createdByName;

  const ExpenseRecord({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.kind,
    required this.createdAt,
    required this.createdByUid,
    required this.createdByName,
  });

  factory ExpenseRecord.fromMap(Map<String, dynamic> map, String id) {
    final category = map['category']?.toString() ?? 'General';

    return ExpenseRecord(
      id: id,
      description: map['description']?.toString() ?? '',
      category: category,
      amount: _readDouble(map['amount']),
      kind: _readExpenseKind(map['kind'], category),
      createdAt: _readDateTime(map['createdAt'] ?? map['date']),
      createdByUid: map['createdByUid']?.toString() ?? '',
      createdByName: map['createdByName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'category': category,
      'amount': amount,
      'kind': kind.name,
      'createdAt': createdAt,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
    };
  }
}

class TopSellingItem {
  final String productId;
  final String productName;
  final int quantitySold;
  final double revenue;
  final double grossProfit;

  const TopSellingItem({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.grossProfit,
  });
}

class DashboardSummary {
  final double totalRevenue;
  final double grossProfit;
  final double operatingExpenses;
  final double withdrawalExpenses;
  final double netProfit;
  final double inventoryValue;
  final double restockSpend;
  final double todayRevenue;
  final int todaySalesCount;
  final int totalUnitsInStock;
  final int productCount;
  final int salesCount;
  final int purchaseCount;
  final List<Product> lowStockProducts;
  final List<TopSellingItem> topSellingItems;
  final List<SaleRecord> recentSales;
  final List<ExpenseRecord> recentExpenses;
  final List<PurchaseRecord> recentPurchases;

  const DashboardSummary({
    required this.totalRevenue,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.withdrawalExpenses,
    required this.netProfit,
    required this.inventoryValue,
    required this.restockSpend,
    required this.todayRevenue,
    required this.todaySalesCount,
    required this.totalUnitsInStock,
    required this.productCount,
    required this.salesCount,
    required this.purchaseCount,
    required this.lowStockProducts,
    required this.topSellingItems,
    required this.recentSales,
    required this.recentExpenses,
    required this.recentPurchases,
  });

  factory DashboardSummary.empty() {
    return const DashboardSummary(
      totalRevenue: 0,
      grossProfit: 0,
      operatingExpenses: 0,
      withdrawalExpenses: 0,
      netProfit: 0,
      inventoryValue: 0,
      restockSpend: 0,
      todayRevenue: 0,
      todaySalesCount: 0,
      totalUnitsInStock: 0,
      productCount: 0,
      salesCount: 0,
      purchaseCount: 0,
      lowStockProducts: <Product>[],
      topSellingItems: <TopSellingItem>[],
      recentSales: <SaleRecord>[],
      recentExpenses: <ExpenseRecord>[],
      recentPurchases: <PurchaseRecord>[],
    );
  }

  factory DashboardSummary.fromData({
    required List<Product> products,
    required List<SaleRecord> sales,
    required List<PurchaseRecord> purchases,
    required List<ExpenseRecord> expenses,
  }) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final totalRevenue = sales.fold<double>(
      0,
      (total, sale) => total + sale.totalRevenue,
    );
    final grossProfit = sales.fold<double>(
      0,
      (total, sale) => total + sale.grossProfit,
    );
    final operatingExpenses = expenses
        .where((item) => item.kind == ExpenseKind.operating)
        .fold<double>(0, (total, item) => total + item.amount);
    final withdrawalExpenses = expenses
        .where((item) => item.kind == ExpenseKind.withdrawal)
        .fold<double>(0, (total, item) => total + item.amount);
    final inventoryValue = products.fold<double>(
      0,
      (total, product) => total + (product.averageCost * product.stock),
    );
    final restockSpend = purchases.fold<double>(
      0,
      (total, purchase) => total + purchase.totalCost,
    );
    final todaySales = sales
        .where((sale) => !sale.createdAt.isBefore(startOfToday))
        .toList();
    final topSellers = <String, TopSellingItem>{};

    for (final sale in sales) {
      for (final item in sale.items) {
        final existing = topSellers[item.productId];
        topSellers[item.productId] = TopSellingItem(
          productId: item.productId,
          productName: item.productName,
          quantitySold: (existing?.quantitySold ?? 0) + item.quantity,
          revenue: (existing?.revenue ?? 0) + item.lineTotal,
          grossProfit: (existing?.grossProfit ?? 0) + item.lineProfit,
        );
      }
    }

    final sortedTopSellers = topSellers.values.toList()
      ..sort((a, b) {
        final byQty = b.quantitySold.compareTo(a.quantitySold);
        if (byQty != 0) {
          return byQty;
        }

        return b.revenue.compareTo(a.revenue);
      });

    final lowStockProducts =
        products.where((product) => product.isLowStock).toList()
          ..sort((a, b) => a.stock.compareTo(b.stock));
    final recentSales = [...sales]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentExpenses = [...expenses]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentPurchases = [...purchases]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DashboardSummary(
      totalRevenue: totalRevenue,
      grossProfit: grossProfit,
      operatingExpenses: operatingExpenses,
      withdrawalExpenses: withdrawalExpenses,
      netProfit: grossProfit - operatingExpenses - withdrawalExpenses,
      inventoryValue: inventoryValue,
      restockSpend: restockSpend,
      todayRevenue: todaySales.fold<double>(
        0,
        (total, sale) => total + sale.totalRevenue,
      ),
      todaySalesCount: todaySales.length,
      totalUnitsInStock: products.fold<int>(
        0,
        (total, product) => total + product.stock,
      ),
      productCount: products.length,
      salesCount: sales.length,
      purchaseCount: purchases.length,
      lowStockProducts: lowStockProducts,
      topSellingItems: sortedTopSellers.take(5).toList(),
      recentSales: recentSales.take(5).toList(),
      recentExpenses: recentExpenses.take(5).toList(),
      recentPurchases: recentPurchases.take(5).toList(),
    );
  }
}
