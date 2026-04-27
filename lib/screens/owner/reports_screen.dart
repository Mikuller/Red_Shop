import 'package:flutter/material.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('reports')),
        actions: const [LanguageMenuButton()],
      ),
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
                        title: strings.t('grossProfit'),
                        value: formatCurrency(summary.grossProfit),
                        subtitle: strings.t('revenueMinusCost'),
                        icon: Icons.trending_up_outlined,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardStatCard(
                        title: strings.t('netProfit'),
                        value: formatCurrency(summary.netProfit),
                        subtitle: strings.t('afterExpensesAndWithdrawals'),
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
                        title: strings.t('restockSpend'),
                        value: formatCurrency(summary.restockSpend),
                        subtitle: strings.t('purchaseRecords', {
                          'count': '${summary.purchaseCount}',
                        }),
                        icon: Icons.local_shipping_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardStatCard(
                        title: strings.t('operatingExpenses'),
                        value: formatCurrency(summary.operatingExpenses),
                        subtitle: strings.t('withdrawalAmount', {
                          'amount': formatCurrency(summary.withdrawalExpenses),
                        }),
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
                        strings.t('bestSellingItems'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (summary.topSellingItems.isEmpty)
                        Text(
                          strings.t('topPerformersEmpty'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...summary.topSellingItems.map(
                          (item) => SummaryRow(
                            label:
                                '${item.productName} | ${item.quantitySold} ${strings.t('pcs')}',
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
                        strings.t('recentSales'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (summary.recentSales.isEmpty)
                        Text(
                          strings.t('noSalesYet'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...summary.recentSales.map(
                          (sale) => SummaryRow(
                            label:
                                '${formatDateTime(sale.createdAt)} | ${sale.processedByName.isEmpty ? strings.t('saleFallback') : sale.processedByName}',
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
                        strings.t('recentExpenses'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (summary.recentExpenses.isEmpty)
                        Text(
                          strings.t('noExpensesYet'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...summary.recentExpenses.map(
                          (expense) => SummaryRow(
                            label:
                                '${expense.description} | ${strings.expenseKindLabel(expense.kind)}',
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
                        strings.t('recentRestocks'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (summary.recentPurchases.isEmpty)
                        Text(
                          strings.t('noRestockYet'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...summary.recentPurchases.map(
                          (purchase) => SummaryRow(
                            label:
                                '${purchase.supplier.isEmpty ? strings.t('purchaseLabel') : purchase.supplier} | ${strings.t('itemLines', {'count': '${purchase.items.length}'})}',
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
