import 'package:flutter/material.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ShopService _shopService = ShopService();
  late ReportRange _range;

  @override
  void initState() {
    super.initState();
    _range = ReportRange.daily();
  }

  void _selectPreset(ReportPreset preset) {
    setState(() {
      _range = switch (preset) {
        ReportPreset.daily => ReportRange.daily(),
        ReportPreset.weekly => ReportRange.weekly(),
        ReportPreset.monthly => ReportRange.monthly(),
        ReportPreset.custom => _range.preset == ReportPreset.custom
            ? _range
            : ReportRange.custom(DateTime.now(), DateTime.now()),
      };
    });
  }

  Future<void> _pickCustomRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _range.start,
        end: _range.end.subtract(const Duration(days: 1)),
      ),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _range = ReportRange.custom(selected.start, selected.end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('reports')),
        actions: const [LanguageMenuButton()],
      ),
      body: StreamBuilder<ReportSummary>(
        stream: _shopService.watchReportSummary(_range),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = snapshot.data ?? ReportSummary.empty(_range);
          final hasActivity =
              summary.salesCount > 0 ||
              summary.purchaseCount > 0 ||
              summary.expenseCount > 0;

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 880;
              final metricColumns = constraints.maxWidth > 1040
                  ? 4
                  : constraints.maxWidth > 620
                  ? 2
                  : 1;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.t('reportRange'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final preset in ReportPreset.values)
                                ChoiceChip(
                                  label: Text(_presetLabel(strings, preset)),
                                  selected: _range.preset == preset,
                                  onSelected: (_) {
                                    _selectPreset(preset);
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatDateRange(summary.range.start, summary.range.end),
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              if (_range.preset == ReportPreset.custom)
                                TextButton.icon(
                                  onPressed: _pickCustomRange,
                                  icon: const Icon(Icons.date_range_outlined),
                                  label: Text(strings.t('pickDates')),
                                ),
                            ],
                          ),
                          if (!hasActivity) ...[
                            const SizedBox(height: 10),
                            Text(
                              strings.t('noDataInRange'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: metricColumns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: metricColumns == 1 ? 176 : 156,
                      ),
                      children: [
                        _TrendMetricCard(
                          title: strings.t('moneyIn'),
                          amount: summary.revenueTrend.current,
                          delta: summary.revenueTrend,
                          color: AppTheme.success,
                        ),
                        _TrendMetricCard(
                          title: strings.t('grossProfit'),
                          amount: summary.grossProfitTrend.current,
                          delta: summary.grossProfitTrend,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _TrendMetricCard(
                          title: strings.t('netProfit'),
                          amount: summary.netProfitTrend.current,
                          delta: summary.netProfitTrend,
                          color: const Color(0xFFFF7B72),
                        ),
                        _TrendMetricCard(
                          title: strings.t('operatingExpenses'),
                          amount: summary.expenseTrend.current,
                          delta: summary.expenseTrend,
                          color: AppTheme.warning,
                          positiveIsGood: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _SummaryPanel(summary: summary)),
                          const SizedBox(width: 18),
                          Expanded(child: _ExpenseBreakdownPanel(summary: summary)),
                        ],
                      )
                    else ...[
                      _SummaryPanel(summary: summary),
                      const SizedBox(height: 18),
                      _ExpenseBreakdownPanel(summary: summary),
                    ],
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
          );
        },
      ),
    );
  }

  String _presetLabel(AppLocalizer strings, ReportPreset preset) {
    return switch (preset) {
      ReportPreset.daily => strings.t('daily'),
      ReportPreset.weekly => strings.t('weekly'),
      ReportPreset.monthly => strings.t('monthly'),
      ReportPreset.custom => strings.t('customRange'),
    };
  }
}

class _TrendMetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final ReportMetricDelta delta;
  final Color color;
  final bool positiveIsGood;

  const _TrendMetricCard({
    required this.title,
    required this.amount,
    required this.delta,
    required this.color,
    this.positiveIsGood = true,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final changeIsPositive = delta.delta >= 0;
    final looksGood = positiveIsGood ? changeIsPositive : !changeIsPositive;
    final deltaColor = looksGood ? AppTheme.success : const Color(0xFFFF7B72);

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withAlpha(26),
            child: Icon(Icons.show_chart_rounded, color: color, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            formatCurrency(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            strings.t('vsPreviousPeriod', {
              'value': formatPercentChange(delta.percentChange),
            }),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: deltaColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final ReportSummary summary;

  const _SummaryPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('periodSummary'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SummaryRow(
            label: strings.t('salesCountLabel'),
            value: '${summary.salesCount}',
            emphasize: true,
          ),
          SummaryRow(
            label: strings.t('unitsSold'),
            value: '${summary.unitsSold}',
          ),
          SummaryRow(
            label: strings.t('purchaseCountLabel'),
            value: '${summary.purchaseCount}',
          ),
          SummaryRow(
            label: strings.t('expenseCountLabel'),
            value: '${summary.expenseCount}',
          ),
          SummaryRow(
            label: strings.t('restockSpend'),
            value: formatCurrency(summary.restockSpend),
          ),
          SummaryRow(
            label: strings.t('withdrawals'),
            value: formatCurrency(summary.withdrawalExpenses),
          ),
        ],
      ),
    );
  }
}

class _ExpenseBreakdownPanel extends StatelessWidget {
  final ReportSummary summary;

  const _ExpenseBreakdownPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('expenseBreakdown'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (summary.expenseCategories.isEmpty)
            Text(
              strings.t('noExpensesYet'),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...summary.expenseCategories.map(
              (category) => SummaryRow(
                label:
                    '${category.category} | ${strings.t('expenseEntriesCount', {'count': '${category.count}'})}',
                value: formatCurrency(category.amount),
              ),
            ),
        ],
      ),
    );
  }
}
