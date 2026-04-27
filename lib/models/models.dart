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

  double averageCostAfterRestock({
    required int addedQuantity,
    required double purchaseUnitCost,
  }) {
    if (addedQuantity <= 0) {
      throw ArgumentError.value(
        addedQuantity,
        'addedQuantity',
        'Restock quantity must be greater than zero.',
      );
    }

    if (purchaseUnitCost < 0) {
      throw ArgumentError.value(
        purchaseUnitCost,
        'purchaseUnitCost',
        'Purchase price cannot be negative.',
      );
    }

    if (stock <= 0) {
      return purchaseUnitCost;
    }

    final existingInventoryValue = stock * averageCost;
    final incomingInventoryValue = addedQuantity * purchaseUnitCost;
    final totalUnits = stock + addedQuantity;

    return (existingInventoryValue + incomingInventoryValue) / totalUnits;
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

enum ReportPreset { daily, weekly, monthly, custom }

DateTime _startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _startOfWeek(DateTime value) {
  final day = _startOfDay(value);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime _startOfMonth(DateTime value) {
  return DateTime(value.year, value.month);
}

bool _isWithinRange(DateTime value, DateTime start, DateTime end) {
  return !value.isBefore(start) && value.isBefore(end);
}

List<TopSellingItem> _buildTopSellers(List<SaleRecord> sales, {int limit = 5}) {
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

  final sorted = topSellers.values.toList()
    ..sort((a, b) {
      final byQty = b.quantitySold.compareTo(a.quantitySold);
      if (byQty != 0) {
        return byQty;
      }

      return b.revenue.compareTo(a.revenue);
    });

  return sorted.take(limit).toList();
}

class ReportRange {
  final ReportPreset preset;
  final DateTime start;
  final DateTime end;

  const ReportRange({
    required this.preset,
    required this.start,
    required this.end,
  });

  factory ReportRange.daily({DateTime? now}) {
    final anchor = _startOfDay(now ?? DateTime.now());
    return ReportRange(
      preset: ReportPreset.daily,
      start: anchor,
      end: anchor.add(const Duration(days: 1)),
    );
  }

  factory ReportRange.weekly({DateTime? now}) {
    final anchor = _startOfWeek(now ?? DateTime.now());
    return ReportRange(
      preset: ReportPreset.weekly,
      start: anchor,
      end: anchor.add(const Duration(days: 7)),
    );
  }

  factory ReportRange.monthly({DateTime? now}) {
    final anchor = _startOfMonth(now ?? DateTime.now());
    return ReportRange(
      preset: ReportPreset.monthly,
      start: anchor,
      end: DateTime(anchor.year, anchor.month + 1),
    );
  }

  factory ReportRange.custom(DateTime start, DateTime endInclusive) {
    final normalizedStart = _startOfDay(start);
    final normalizedEnd = _startOfDay(endInclusive).add(const Duration(days: 1));
    return ReportRange(
      preset: ReportPreset.custom,
      start: normalizedStart,
      end: normalizedEnd,
    );
  }

  Duration get duration => end.difference(start);

  ReportRange previous() {
    final previousEnd = start;
    final previousStart = previousEnd.subtract(duration);
    return ReportRange(
      preset: preset,
      start: previousStart,
      end: previousEnd,
    );
  }

  bool contains(DateTime value) {
    return _isWithinRange(value, start, end);
  }
}

class ReportMetricDelta {
  final double current;
  final double previous;

  const ReportMetricDelta({required this.current, required this.previous});

  double get delta => current - previous;

  double get percentChange {
    if (previous == 0) {
      return current == 0 ? 0 : 1;
    }

    return delta / previous;
  }
}

class ExpenseCategorySummary {
  final String category;
  final double amount;
  final int count;

  const ExpenseCategorySummary({
    required this.category,
    required this.amount,
    required this.count,
  });
}

class ReportSummary {
  final ReportRange range;
  final ReportRange previousRange;
  final ReportMetricDelta revenueTrend;
  final ReportMetricDelta grossProfitTrend;
  final ReportMetricDelta netProfitTrend;
  final ReportMetricDelta expenseTrend;
  final double operatingExpenses;
  final double withdrawalExpenses;
  final double restockSpend;
  final int salesCount;
  final int purchaseCount;
  final int expenseCount;
  final int unitsSold;
  final List<TopSellingItem> topSellingItems;
  final List<ExpenseCategorySummary> expenseCategories;
  final List<SaleRecord> recentSales;
  final List<ExpenseRecord> recentExpenses;
  final List<PurchaseRecord> recentPurchases;

  const ReportSummary({
    required this.range,
    required this.previousRange,
    required this.revenueTrend,
    required this.grossProfitTrend,
    required this.netProfitTrend,
    required this.expenseTrend,
    required this.operatingExpenses,
    required this.withdrawalExpenses,
    required this.restockSpend,
    required this.salesCount,
    required this.purchaseCount,
    required this.expenseCount,
    required this.unitsSold,
    required this.topSellingItems,
    required this.expenseCategories,
    required this.recentSales,
    required this.recentExpenses,
    required this.recentPurchases,
  });

  factory ReportSummary.empty(ReportRange range) {
    return ReportSummary(
      range: range,
      previousRange: range.previous(),
      revenueTrend: const ReportMetricDelta(current: 0, previous: 0),
      grossProfitTrend: const ReportMetricDelta(current: 0, previous: 0),
      netProfitTrend: const ReportMetricDelta(current: 0, previous: 0),
      expenseTrend: const ReportMetricDelta(current: 0, previous: 0),
      operatingExpenses: 0,
      withdrawalExpenses: 0,
      restockSpend: 0,
      salesCount: 0,
      purchaseCount: 0,
      expenseCount: 0,
      unitsSold: 0,
      topSellingItems: const <TopSellingItem>[],
      expenseCategories: const <ExpenseCategorySummary>[],
      recentSales: const <SaleRecord>[],
      recentExpenses: const <ExpenseRecord>[],
      recentPurchases: const <PurchaseRecord>[],
    );
  }

  factory ReportSummary.fromData({
    required ReportRange range,
    required List<SaleRecord> sales,
    required List<PurchaseRecord> purchases,
    required List<ExpenseRecord> expenses,
  }) {
    final previousRange = range.previous();
    final scopedSales =
        sales.where((sale) => range.contains(sale.createdAt)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final scopedPurchases =
        purchases.where((purchase) => range.contains(purchase.createdAt)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final scopedExpenses =
        expenses.where((expense) => range.contains(expense.createdAt)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final previousSales = sales
        .where((sale) => previousRange.contains(sale.createdAt))
        .toList();
    final previousExpenses = expenses
        .where((expense) => previousRange.contains(expense.createdAt))
        .toList();

    final revenue = scopedSales.fold<double>(
      0,
      (total, sale) => total + sale.totalRevenue,
    );
    final previousRevenue = previousSales.fold<double>(
      0,
      (total, sale) => total + sale.totalRevenue,
    );
    final grossProfit = scopedSales.fold<double>(
      0,
      (total, sale) => total + sale.grossProfit,
    );
    final previousGrossProfit = previousSales.fold<double>(
      0,
      (total, sale) => total + sale.grossProfit,
    );
    final operatingExpenses = scopedExpenses
        .where((expense) => expense.kind == ExpenseKind.operating)
        .fold<double>(0, (total, expense) => total + expense.amount);
    final previousOperatingExpenses = previousExpenses
        .where((expense) => expense.kind == ExpenseKind.operating)
        .fold<double>(0, (total, expense) => total + expense.amount);
    final withdrawalExpenses = scopedExpenses
        .where((expense) => expense.kind == ExpenseKind.withdrawal)
        .fold<double>(0, (total, expense) => total + expense.amount);
    final previousWithdrawalExpenses = previousExpenses
        .where((expense) => expense.kind == ExpenseKind.withdrawal)
        .fold<double>(0, (total, expense) => total + expense.amount);
    final restockSpend = scopedPurchases.fold<double>(
      0,
      (total, purchase) => total + purchase.totalCost,
    );
    final unitsSold = scopedSales.fold<int>(
      0,
      (total, sale) =>
          total +
          sale.items.fold<int>(0, (sum, item) => sum + item.quantity),
    );

    final categoryTotals = <String, ExpenseCategorySummary>{};
    for (final expense in scopedExpenses) {
      final category = expense.category.trim().isEmpty
          ? 'General'
          : expense.category.trim();
      final existing = categoryTotals[category];
      categoryTotals[category] = ExpenseCategorySummary(
        category: category,
        amount: (existing?.amount ?? 0) + expense.amount,
        count: (existing?.count ?? 0) + 1,
      );
    }

    final sortedCategories = categoryTotals.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return ReportSummary(
      range: range,
      previousRange: previousRange,
      revenueTrend: ReportMetricDelta(
        current: revenue,
        previous: previousRevenue,
      ),
      grossProfitTrend: ReportMetricDelta(
        current: grossProfit,
        previous: previousGrossProfit,
      ),
      netProfitTrend: ReportMetricDelta(
        current: grossProfit - operatingExpenses - withdrawalExpenses,
        previous:
            previousGrossProfit -
            previousOperatingExpenses -
            previousWithdrawalExpenses,
      ),
      expenseTrend: ReportMetricDelta(
        current: operatingExpenses + withdrawalExpenses,
        previous: previousOperatingExpenses + previousWithdrawalExpenses,
      ),
      operatingExpenses: operatingExpenses,
      withdrawalExpenses: withdrawalExpenses,
      restockSpend: restockSpend,
      salesCount: scopedSales.length,
      purchaseCount: scopedPurchases.length,
      expenseCount: scopedExpenses.length,
      unitsSold: unitsSold,
      topSellingItems: _buildTopSellers(scopedSales),
      expenseCategories: sortedCategories.take(5).toList(),
      recentSales: scopedSales.take(5).toList(),
      recentExpenses: scopedExpenses.take(5).toList(),
      recentPurchases: scopedPurchases.take(5).toList(),
    );
  }
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
    final sortedTopSellers = _buildTopSellers(sales);

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
      topSellingItems: sortedTopSellers,
      recentSales: recentSales.take(5).toList(),
      recentExpenses: recentExpenses.take(5).toList(),
      recentPurchases: recentPurchases.take(5).toList(),
    );
  }
}
