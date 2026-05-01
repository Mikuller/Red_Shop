import 'enums.dart';
import 'product_model.dart';
import 'sale_model.dart';
import 'purchase_model.dart';
import 'expense_model.dart';
import 'service_model.dart';

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
  final int fastMoneyCount;
  final double posSalesRevenue;
  final double posSalesProfit;
  final double fastMoneyRevenue;
  final double fastMoneyProfit;
  final int purchaseCount;
  final int expenseCount;
  final int serviceCount;
  final double serviceChargeTotal;
  final double serviceNetIncomeTotal;
  final double paidServiceIncome;
  final double unpaidServiceIncome;
  final int unitsSold;
  final List<TopSellingItem> topSellingItems;
  final List<ExpenseCategorySummary> expenseCategories;
  final List<SaleRecord> recentSales;
  final List<SaleRecord> recentPosSales;
  final List<SaleRecord> recentFastMoneySales;
  final List<ServiceRecord> recentServices;
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
    required this.fastMoneyCount,
    required this.posSalesRevenue,
    required this.posSalesProfit,
    required this.fastMoneyRevenue,
    required this.fastMoneyProfit,
    required this.purchaseCount,
    required this.expenseCount,
    required this.serviceCount,
    required this.serviceChargeTotal,
    required this.serviceNetIncomeTotal,
    required this.paidServiceIncome,
    required this.unpaidServiceIncome,
    required this.unitsSold,
    required this.topSellingItems,
    required this.expenseCategories,
    required this.recentSales,
    required this.recentPosSales,
    required this.recentFastMoneySales,
    required this.recentServices,
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
      fastMoneyCount: 0,
      posSalesRevenue: 0,
      posSalesProfit: 0,
      fastMoneyRevenue: 0,
      fastMoneyProfit: 0,
      purchaseCount: 0,
      expenseCount: 0,
      serviceCount: 0,
      serviceChargeTotal: 0,
      serviceNetIncomeTotal: 0,
      paidServiceIncome: 0,
      unpaidServiceIncome: 0,
      unitsSold: 0,
      topSellingItems: const <TopSellingItem>[],
      expenseCategories: const <ExpenseCategorySummary>[],
      recentSales: const <SaleRecord>[],
      recentPosSales: const <SaleRecord>[],
      recentFastMoneySales: const <SaleRecord>[],
      recentServices: const <ServiceRecord>[],
      recentExpenses: const <ExpenseRecord>[],
      recentPurchases: const <PurchaseRecord>[],
    );
  }

  factory ReportSummary.fromData({
    required ReportRange range,
    required List<SaleRecord> sales,
    required List<PurchaseRecord> purchases,
    required List<ExpenseRecord> expenses,
    required List<ServiceRecord> services,
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
    final scopedServices =
        services.where((service) => range.contains(service.createdAt)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final previousSales = sales
        .where((sale) => previousRange.contains(sale.createdAt))
        .toList();
    final previousExpenses = expenses
        .where((expense) => previousRange.contains(expense.createdAt))
        .toList();
    final previousServices = services
        .where((service) => previousRange.contains(service.createdAt))
        .toList();

    final saleRevenue = scopedSales.fold<double>(
      0,
      (total, sale) => total + sale.totalRevenue,
    );
    final serviceRevenue = scopedServices.fold<double>(
      0,
      (total, service) => total + service.serviceCharge,
    );
    final revenue = saleRevenue + serviceRevenue;
    final previousSaleRevenue = previousSales.fold<double>(
      0,
      (total, sale) => total + sale.totalRevenue,
    );
    final previousServiceRevenue = previousServices.fold<double>(
      0,
      (total, service) => total + service.serviceCharge,
    );
    final previousRevenue = previousSaleRevenue + previousServiceRevenue;
    final saleGrossProfit = scopedSales.fold<double>(
      0,
      (total, sale) => total + sale.grossProfit,
    );
    final serviceGrossProfit = scopedServices.fold<double>(
      0,
      (total, service) => total + service.netIncome,
    );
    final grossProfit = saleGrossProfit + serviceGrossProfit;
    final previousSaleGrossProfit = previousSales.fold<double>(
      0,
      (total, sale) => total + sale.grossProfit,
    );
    final previousServiceGrossProfit = previousServices.fold<double>(
      0,
      (total, service) => total + service.netIncome,
    );
    final previousGrossProfit =
        previousSaleGrossProfit + previousServiceGrossProfit;
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
    final posSales = scopedSales.where((sale) => !sale.isInstantSale).toList();
    final fastMoneySales = scopedSales.where((sale) => sale.isInstantSale).toList();
    final fastMoneyCount = scopedSales
        .where((sale) => sale.isInstantSale)
        .length;
    final posSalesRevenue = posSales.fold<double>(
      0,
      (total, sale) => total + sale.totalRevenue,
    );
    final posSalesProfit = posSales.fold<double>(
      0,
      (total, sale) => total + sale.grossProfit,
    );
    final fastMoneyRevenue = fastMoneySales.fold<double>(
      0,
      (total, sale) => total + sale.totalRevenue,
    );
    final fastMoneyProfit = fastMoneySales.fold<double>(
      0,
      (total, sale) => total + sale.grossProfit,
    );
    final serviceNetIncomeTotal = scopedServices.fold<double>(
      0,
      (total, service) => total + service.netIncome,
    );
    final paidServiceIncome = scopedServices
        .where((service) => service.status == ServiceStatus.completedPaid)
        .fold<double>(0, (total, service) => total + service.serviceCharge);
    final unpaidServiceIncome = scopedServices
        .where((service) => service.status == ServiceStatus.completedUnpaid)
        .fold<double>(0, (total, service) => total + service.serviceCharge);
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
      fastMoneyCount: fastMoneyCount,
      posSalesRevenue: posSalesRevenue,
      posSalesProfit: posSalesProfit,
      fastMoneyRevenue: fastMoneyRevenue,
      fastMoneyProfit: fastMoneyProfit,
      purchaseCount: scopedPurchases.length,
      expenseCount: scopedExpenses.length,
      serviceCount: scopedServices.length,
      serviceChargeTotal: serviceRevenue,
      serviceNetIncomeTotal: serviceNetIncomeTotal,
      paidServiceIncome: paidServiceIncome,
      unpaidServiceIncome: unpaidServiceIncome,
      unitsSold: unitsSold,
      topSellingItems: _buildTopSellers(scopedSales),
      expenseCategories: sortedCategories.take(5).toList(),
      recentSales: scopedSales.take(5).toList(),
      recentPosSales: posSales.take(5).toList(),
      recentFastMoneySales: fastMoneySales.take(5).toList(),
      recentServices: scopedServices.take(5).toList(),
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
    required List<ServiceRecord> services,
  }) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final saleRevenue = sales.fold<double>(
      0,
      (total, sale) => total + sale.totalRevenue,
    );
    final serviceRevenue = services.fold<double>(
      0,
      (total, service) => total + service.serviceCharge,
    );
    final totalRevenue = saleRevenue + serviceRevenue;
    final saleGrossProfit = sales.fold<double>(
      0,
      (total, sale) => total + sale.grossProfit,
    );
    final serviceGrossProfit = services.fold<double>(
      0,
      (total, service) => total + service.netIncome,
    );
    final grossProfit = saleGrossProfit + serviceGrossProfit;
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
