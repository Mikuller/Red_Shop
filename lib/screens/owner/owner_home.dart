import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/screens/owner/expense_screen.dart';
import 'package:red_shop/screens/owner/inventory_screen.dart';
import 'package:red_shop/screens/owner/reports_screen.dart';
import 'package:red_shop/screens/owner/restock_screen.dart';
import 'package:red_shop/screens/owner/staff_screen.dart';
import 'package:red_shop/screens/pos/pos_screen.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class OwnerHome extends StatelessWidget {
  const OwnerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ShopAuthProvider>();
    final user = auth.userModel;
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('appName')),
            Text(
              user?.name ?? strings.t('ownerConsole'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          const LanguageMenuButton(),
          IconButton(
            tooltip: strings.t('openPos'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PosScreen(title: strings.t('ownerPos')),
                ),
              );
            },
            icon: const Icon(Icons.point_of_sale_outlined),
          ),
          IconButton(
            tooltip: strings.t('logout'),
            onPressed: () => context.read<ShopAuthProvider>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DashboardSummary>(
        stream: ShopService().watchDashboardSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = snapshot.data ?? DashboardSummary.empty();

          return LayoutBuilder(
            builder: (context, constraints) {
              final statCrossAxisCount = constraints.maxWidth > 920 ? 4 : 2;
              final actionCrossAxisCount = constraints.maxWidth > 920 ? 3 : 2;
              final statCardHeight = constraints.maxWidth > 920 ? 168.0 : 196.0;
              final actionCardHeight = constraints.maxWidth > 920
                  ? 168.0
                  : 188.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(user: user, summary: summary),
                    const SizedBox(height: 18),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: statCrossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: statCardHeight,
                      ),
                      children: [
                        DashboardStatCard(
                          title: strings.t('moneyIn'),
                          value: formatCurrency(summary.totalRevenue),
                          subtitle: strings.t('salesDone', {
                            'count': '${summary.salesCount}',
                          }),
                          icon: Icons.payments_outlined,
                          color: AppTheme.success,
                        ),
                        DashboardStatCard(
                          title: strings.t('profit'),
                          value: formatCurrency(summary.grossProfit),
                          subtitle: strings.t('beforeShopCosts'),
                          icon: Icons.trending_up_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        DashboardStatCard(
                          title: strings.t('costs'),
                          value: formatCurrency(
                            summary.operatingExpenses +
                                summary.withdrawalExpenses,
                          ),
                          subtitle: strings.t('shopCostsAndTakeouts'),
                          icon: Icons.receipt_long_outlined,
                          color: AppTheme.warning,
                        ),
                        DashboardStatCard(
                          title: strings.t('stockValue'),
                          value: formatCurrency(summary.inventoryValue),
                          subtitle: strings.t('unitsInStockCount', {
                            'count': '${summary.totalUnitsInStock}',
                          }),
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFF6FA8FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      strings.t('quickActions'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: actionCrossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: actionCardHeight,
                      ),
                      children: [
                        ActionShortcutCard(
                          icon: Icons.inventory_2_outlined,
                          title: strings.t('inventory'),
                          subtitle: strings.t('inventoryShort'),
                          hint: strings.t('tapToOpen'),
                          color: const Color(0xFF6FA8FF),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const InventoryScreen(),
                              ),
                            );
                          },
                        ),
                        ActionShortcutCard(
                          icon: Icons.local_shipping_outlined,
                          title: strings.t('restocking'),
                          subtitle: strings.t('recordPurchaseArrivals'),
                          hint: strings.t('tapToOpen'),
                          color: AppTheme.warning,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RestockScreen(),
                              ),
                            );
                          },
                        ),
                        ActionShortcutCard(
                          icon: Icons.point_of_sale_outlined,
                          title: strings.t('pos'),
                          subtitle: strings.t('startSale'),
                          hint: strings.t('tapToOpen'),
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PosScreen(title: strings.t('ownerPos')),
                              ),
                            );
                          },
                        ),
                        ActionShortcutCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: strings.t('expenses'),
                          subtitle: strings.t('trackSpendAndWithdrawals'),
                          hint: strings.t('tapToOpen'),
                          color: const Color(0xFFFF7B72),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ExpenseScreen(),
                              ),
                            );
                          },
                        ),
                        ActionShortcutCard(
                          icon: Icons.bar_chart_outlined,
                          title: strings.t('reports'),
                          subtitle: strings.t('profitAndBestSellers'),
                          hint: strings.t('tapToOpen'),
                          color: AppTheme.success,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReportsScreen(),
                              ),
                            );
                          },
                        ),
                        ActionShortcutCard(
                          icon: Icons.group_outlined,
                          title: strings.t('staff'),
                          subtitle: strings.t('createManageAccess'),
                          hint: strings.t('tapToOpen'),
                          color: const Color(0xFFA78BFA),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const StaffScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _TopSellersPanel(summary: summary),
                    const SizedBox(height: 18),
                    _LowStockPanel(summary: summary),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final UserModel? user;
  final DashboardSummary summary;

  const _HeroCard({required this.user, required this.summary});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF451018), Color(0xFF1A0A0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('welcomeBack', {'name': _firstName(context, user?.name)}),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            strings.t('todaySummary', {
              'count': '${summary.todaySalesCount}',
              'amount': formatCurrency(summary.todayRevenue),
            }),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              HeroMetricBadge(
                icon: Icons.trending_up_outlined,
                label: strings.t('netProfit'),
                value: formatCurrency(summary.netProfit),
                hint: strings.t('tapToOpen'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                },
              ),
              HeroMetricBadge(
                icon: Icons.warning_amber_rounded,
                label: strings.t('lowStock'),
                value: strings.t('itemCountShort', {
                  'count': '${summary.lowStockProducts.length}',
                }),
                hint: strings.t('tapToOpen'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const InventoryScreen(startLowStockOnly: true),
                    ),
                  );
                },
              ),
              HeroMetricBadge(
                icon: Icons.shopping_bag_outlined,
                label: strings.t('restocks'),
                value: formatCurrency(summary.restockSpend),
                hint: strings.t('tapToOpen'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RestockScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _firstName(BuildContext context, String? name) {
    if (name == null || name.trim().isEmpty) {
      return context.strings.t('ownerFallbackName');
    }

    return name.trim().split(' ').first;
  }
}

class _TopSellersPanel extends StatelessWidget {
  final DashboardSummary summary;

  const _TopSellersPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('topSellers'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (summary.topSellingItems.isEmpty)
            Text(
              strings.t('topSellersEmpty'),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...summary.topSellingItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(28),
                      child: Text(
                        item.quantitySold.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            strings.t('revenueProfitLine', {
                              'revenue': formatCurrency(item.revenue),
                              'profit': formatCurrency(item.grossProfit),
                            }),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  final DashboardSummary summary;

  const _LowStockPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('lowStockWatch'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (summary.lowStockProducts.isEmpty)
            Text(
              strings.t('allStockOkay'),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...summary.lowStockProducts
                .take(5)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                product.category.isEmpty
                                    ? strings.t('thresholdOnly', {
                                        'count': '${product.lowStockThreshold}',
                                      })
                                    : strings.t('thresholdWithCategory', {
                                        'category': product.category,
                                        'count': '${product.lowStockThreshold}',
                                      }),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        StockBadge(product: product),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
