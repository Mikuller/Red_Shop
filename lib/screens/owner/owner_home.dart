import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Red Computer'),
            Text(
              user?.name ?? 'Owner console',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open POS',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PosScreen(title: 'Owner POS'),
                ),
              );
            },
            icon: const Icon(Icons.point_of_sale_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
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

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(user: user, summary: summary),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: statCrossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.3,
                      children: [
                        DashboardStatCard(
                          title: 'Total revenue',
                          value: formatCurrency(summary.totalRevenue),
                          subtitle: '${summary.salesCount} completed sales',
                          icon: Icons.payments_outlined,
                          color: AppTheme.success,
                        ),
                        DashboardStatCard(
                          title: 'Gross profit',
                          value: formatCurrency(summary.grossProfit),
                          subtitle: 'Before expenses and withdrawals',
                          icon: Icons.trending_up_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        DashboardStatCard(
                          title: 'Expenses',
                          value: formatCurrency(
                            summary.operatingExpenses +
                                summary.withdrawalExpenses,
                          ),
                          subtitle: 'Operating + withdrawals',
                          icon: Icons.receipt_long_outlined,
                          color: AppTheme.warning,
                        ),
                        DashboardStatCard(
                          title: 'Inventory value',
                          value: formatCurrency(summary.inventoryValue),
                          subtitle:
                              '${summary.totalUnitsInStock} units in stock',
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFF6FA8FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Quick actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: actionCrossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.5,
                      children: [
                        _ActionCard(
                          icon: Icons.inventory_2_outlined,
                          title: 'Inventory',
                          subtitle: 'Products and stock view',
                          color: const Color(0xFF6FA8FF),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const InventoryScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          icon: Icons.local_shipping_outlined,
                          title: 'Restocking',
                          subtitle: 'Record purchase arrivals',
                          color: AppTheme.warning,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RestockScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          icon: Icons.point_of_sale_outlined,
                          title: 'POS',
                          subtitle: 'Start a sale',
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PosScreen(title: 'Owner POS'),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Expenses',
                          subtitle: 'Track spend and withdrawals',
                          color: const Color(0xFFFF7B72),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ExpenseScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          icon: Icons.bar_chart_outlined,
                          title: 'Reports',
                          subtitle: 'Profit and best sellers',
                          color: AppTheme.success,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReportsScreen(),
                              ),
                            );
                          },
                        ),
                        _ActionCard(
                          icon: Icons.group_outlined,
                          title: 'Staff',
                          subtitle: 'Create and manage access',
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
            'Welcome back, ${_firstName(user?.name)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Today: ${summary.todaySalesCount} sale${summary.todaySalesCount == 1 ? '' : 's'} | ${formatCurrency(summary.todayRevenue)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroBadge(
                icon: Icons.trending_up_outlined,
                label: 'Net profit',
                value: formatCurrency(summary.netProfit),
              ),
              _HeroBadge(
                icon: Icons.warning_amber_rounded,
                label: 'Low stock',
                value: '${summary.lowStockProducts.length} items',
              ),
              _HeroBadge(
                icon: Icons.shopping_bag_outlined,
                label: 'Restocks',
                value: formatCurrency(summary.restockSpend),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _firstName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Owner';
    }

    return name.trim().split(' ').first;
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(36),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TopSellersPanel extends StatelessWidget {
  final DashboardSummary summary;

  const _TopSellersPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top sellers', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (summary.topSellingItems.isEmpty)
            Text(
              'Sales will surface your best-performing products here.',
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
                            '${formatCurrency(item.revenue)} revenue | ${formatCurrency(item.grossProfit)} profit',
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
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Low stock watch',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (summary.lowStockProducts.isEmpty)
            Text(
              'Everything is stocked above its threshold right now.',
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
                                    ? 'Threshold ${product.lowStockThreshold}'
                                    : '${product.category} | Threshold ${product.lowStockThreshold}',
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
