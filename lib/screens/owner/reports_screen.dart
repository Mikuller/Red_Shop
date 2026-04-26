import 'package:flutter/material.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: StreamBuilder<DashboardSummary>(
        stream: ShopService().watchDashboardSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = snapshot.data ?? DashboardSummary.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Gross profit',
                        value: formatCurrency(summary.grossProfit),
                        subtitle: 'Revenue minus product cost',
                        icon: Icons.trending_up_outlined,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Net profit',
                        value: formatCurrency(summary.netProfit),
                        subtitle: 'After expenses and withdrawals',
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Restock spend',
                        value: formatCurrency(summary.restockSpend),
                        subtitle: '${summary.purchaseCount} purchase records',
                        icon: Icons.local_shipping_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Operating expenses',
                        value: formatCurrency(summary.operatingExpenses),
                        subtitle:
                            '${formatCurrency(summary.withdrawalExpenses)} withdrawals',
                        icon: Icons.receipt_long_outlined,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best-selling items',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (summary.topSellingItems.isEmpty)
                        Text(
                          'Top performers will appear here after a few sales.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...summary.topSellingItems.map(
                          (item) => SummaryRow(
                            label:
                                '${item.productName} | ${item.quantitySold} pcs',
                            value: formatCurrency(item.revenue),
                            emphasize: true,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent sales',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (summary.recentSales.isEmpty)
                        Text(
                          'No sales have been recorded yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...summary.recentSales.map(
                          (sale) => SummaryRow(
                            label:
                                '${formatDateTime(sale.createdAt)} | ${sale.processedByName.isEmpty ? 'Sale' : sale.processedByName}',
                            value: formatCurrency(sale.totalRevenue),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent expenses',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (summary.recentExpenses.isEmpty)
                        Text(
                          'No expenses have been recorded yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...summary.recentExpenses.map(
                          (expense) => SummaryRow(
                            label:
                                '${expense.description} | ${expenseKindLabel(expense.kind)}',
                            value: formatCurrency(expense.amount),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent restocks',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (summary.recentPurchases.isEmpty)
                        Text(
                          'No restock history yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...summary.recentPurchases.map(
                          (purchase) => SummaryRow(
                            label:
                                '${purchase.supplier.isEmpty ? 'Purchase' : purchase.supplier} | ${purchase.items.length} item lines',
                            value: formatCurrency(purchase.totalCost),
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
    );
  }
}
