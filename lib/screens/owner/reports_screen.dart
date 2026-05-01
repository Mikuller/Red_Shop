import 'package:flutter/material.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

enum _ReportSourceFilter { all, pos, fastMoney, services }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ShopService _shopService = ShopService();
  late ReportRange _range;
  _ReportSourceFilter _sourceFilter = _ReportSourceFilter.all;

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
              summary.expenseCount > 0 ||
              summary.serviceCount > 0;

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
                            strings.t('incomeSource'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final filter in _ReportSourceFilter.values)
                                ChoiceChip(
                                  label: Text(_sourceFilterLabel(strings, filter)),
                                  selected: _sourceFilter == filter,
                                  onSelected: (_) {
                                    setState(() => _sourceFilter = filter);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SourceSummaryPanel(
                              summary: summary,
                              filter: _sourceFilter,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _RecentIncomeActivityPanel(
                              summary: summary,
                              filter: _sourceFilter,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _SourceSummaryPanel(
                        summary: summary,
                        filter: _sourceFilter,
                      ),
                      const SizedBox(height: 18),
                      _RecentIncomeActivityPanel(
                        summary: summary,
                        filter: _sourceFilter,
                      ),
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

  String _sourceFilterLabel(
    AppLocalizer strings,
    _ReportSourceFilter filter,
  ) {
    return switch (filter) {
      _ReportSourceFilter.all => strings.t('all'),
      _ReportSourceFilter.pos => strings.t('pos'),
      _ReportSourceFilter.fastMoney => strings.t('fastMoney'),
      _ReportSourceFilter.services => strings.t('services'),
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
            label: strings.t('fastMoneySalesLabel'),
            value: '${summary.fastMoneyCount}',
          ),
          SummaryRow(
            label: strings.t('unitsSold'),
            value: '${summary.unitsSold}',
          ),
          SummaryRow(
            label: strings.t('serviceCountLabel'),
            value: '${summary.serviceCount}',
          ),
          SummaryRow(
            label: strings.t('serviceChargeTotal'),
            value: formatCurrency(summary.serviceChargeTotal),
          ),
          SummaryRow(
            label: strings.t('paidServiceIncome'),
            value: formatCurrency(summary.paidServiceIncome),
          ),
          SummaryRow(
            label: strings.t('unpaidServiceIncome'),
            value: formatCurrency(summary.unpaidServiceIncome),
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

class _SourceSummaryPanel extends StatelessWidget {
  final ReportSummary summary;
  final _ReportSourceFilter filter;

  const _SourceSummaryPanel({
    required this.summary,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final countLabel = switch (filter) {
      _ReportSourceFilter.all => strings.t('incomeEntries'),
      _ReportSourceFilter.pos => strings.t('salesCountLabel'),
      _ReportSourceFilter.fastMoney => strings.t('fastMoneySalesLabel'),
      _ReportSourceFilter.services => strings.t('serviceCountLabel'),
    };
    final countValue = switch (filter) {
      _ReportSourceFilter.all => summary.salesCount + summary.serviceCount,
      _ReportSourceFilter.pos => summary.salesCount - summary.fastMoneyCount,
      _ReportSourceFilter.fastMoney => summary.fastMoneyCount,
      _ReportSourceFilter.services => summary.serviceCount,
    };
    final incomeValue = switch (filter) {
      _ReportSourceFilter.all => summary.revenueTrend.current,
      _ReportSourceFilter.pos => summary.posSalesRevenue,
      _ReportSourceFilter.fastMoney => summary.fastMoneyRevenue,
      _ReportSourceFilter.services => summary.serviceChargeTotal,
    };
    final profitValue = switch (filter) {
      _ReportSourceFilter.all => summary.grossProfitTrend.current,
      _ReportSourceFilter.pos => summary.posSalesProfit,
      _ReportSourceFilter.fastMoney => summary.fastMoneyProfit,
      _ReportSourceFilter.services => summary.serviceNetIncomeTotal,
    };

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('incomeSourceSummary'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SummaryRow(
            label: countLabel,
            value: '$countValue',
            emphasize: true,
          ),
          SummaryRow(
            label: strings.t('moneyIn'),
            value: formatCurrency(incomeValue),
          ),
          SummaryRow(
            label: strings.t('grossProfit'),
            value: formatCurrency(profitValue),
          ),
        ],
      ),
    );
  }
}

class _RecentIncomeActivityPanel extends StatelessWidget {
  final ReportSummary summary;
  final _ReportSourceFilter filter;

  const _RecentIncomeActivityPanel({
    required this.summary,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final activities = _buildActivities(strings);

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('recentIncomeActivity'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            Text(
              strings.t('noIncomeActivityYet'),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...activities.map(
              (activity) => SummaryRow(
                label: '${activity.title} | ${activity.subtitle}',
                value: formatCurrency(activity.amount),
              ),
            ),
        ],
      ),
    );
  }

  List<_IncomeActivityItem> _buildActivities(AppLocalizer strings) {
    final posItems = summary.recentPosSales
        .map(
          (sale) => _IncomeActivityItem(
            title: sale.primaryName.isEmpty
                ? strings.t('saleFallback')
                : sale.primaryName,
            subtitle: '${strings.t('pos')} | ${formatDateTime(sale.createdAt)}',
            amount: sale.totalRevenue,
            createdAt: sale.createdAt,
          ),
        )
        .toList();
    final fastMoneyItems = summary.recentFastMoneySales
        .map(
          (sale) => _IncomeActivityItem(
            title: sale.primaryName.isEmpty
                ? strings.t('fastMoney')
                : sale.primaryName,
            subtitle:
                '${strings.t('fastMoney')} | ${formatDateTime(sale.createdAt)}',
            amount: sale.totalRevenue,
            createdAt: sale.createdAt,
          ),
        )
        .toList();
    final serviceItems = summary.recentServices
        .map(
          (service) => _IncomeActivityItem(
            title: service.serviceType,
            subtitle:
                '${service.customerName} | ${formatDateTime(service.createdAt)}',
            amount: service.serviceCharge,
            createdAt: service.createdAt,
          ),
        )
        .toList();

    final items = switch (filter) {
      _ReportSourceFilter.all => [
          ...posItems,
          ...fastMoneyItems,
          ...serviceItems,
        ],
      _ReportSourceFilter.pos => posItems,
      _ReportSourceFilter.fastMoney => fastMoneyItems,
      _ReportSourceFilter.services => serviceItems,
    }..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return items.take(5).toList();
  }
}

class _IncomeActivityItem {
  final String title;
  final String subtitle;
  final double amount;
  final DateTime createdAt;

  const _IncomeActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.createdAt,
  });
}
