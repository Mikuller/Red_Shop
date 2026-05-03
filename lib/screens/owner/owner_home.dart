import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/screens/owner/expense_screen.dart';
import 'package:red_shop/screens/owner/inventory_screen.dart';
import 'package:red_shop/screens/owner/reports_screen.dart';
import 'package:red_shop/screens/owner/restock_screen.dart';
import 'package:red_shop/screens/owner/service_screen.dart';
import 'package:red_shop/screens/owner/staff_screen.dart';
import 'package:red_shop/screens/pos/pos_screen.dart';
import 'package:red_shop/screens/shared/fast_money_screen.dart';
import 'package:red_shop/screens/shared/settings_screen.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class OwnerHome extends StatefulWidget {
  const OwnerHome({super.key});

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _dockVisible = ValueNotifier(true);
  double _lastScrollOffset = 0;
  double _scrollDownDistance = 0;
  double _scrollUpDistance = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final pixels = _scrollController.position.pixels;
    final delta = pixels - _lastScrollOffset;
    _lastScrollOffset = pixels;

    if (pixels <= 12) {
      _scrollDownDistance = 0;
      _scrollUpDistance = 0;
      _setDockVisible(true);
      return;
    }

    if (delta.abs() < 1.5) {
      return;
    }

    if (delta > 0) {
      _scrollDownDistance += delta;
      _scrollUpDistance = 0;
      if (_scrollDownDistance >= 28) {
        _scrollDownDistance = 0;
        _setDockVisible(false);
      }
    } else {
      _scrollUpDistance += delta.abs();
      _scrollDownDistance = 0;
      if (_scrollUpDistance >= 18) {
        _scrollUpDistance = 0;
        _setDockVisible(true);
      }
    }
  }

  void _setDockVisible(bool visible) {
    if (!mounted || _dockVisible.value == visible) {
      return;
    }

    _dockVisible.value = visible;
  }

  @override
  void dispose() {
    _dockVisible.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _openScreen(Widget screen) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _showStockSheet() async {
    final strings = context.readStrings;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceAlt,
      showDragHandle: true,
      builder: (context) {
        return _SheetScaffold(
          title: strings.t('stockWorkspace'),
          subtitle: strings.t('stockWorkspaceHint'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetActionTile(
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF6FA8FF),
                title: strings.t('inventory'),
                subtitle: strings.t('inventoryShort'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openScreen(const InventoryScreen());
                },
              ),
              const SizedBox(height: 12),
              _SheetActionTile(
                icon: Icons.local_shipping_outlined,
                color: AppTheme.warning,
                title: strings.t('restocking'),
                subtitle: strings.t('recordPurchaseArrivals'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openScreen(const RestockScreen());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMoreSheet() async {
    final strings = context.readStrings;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceAlt,
      showDragHandle: true,
      builder: (context) {
        return _SheetScaffold(
          title: strings.t('moreActions'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetActionTile(
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFFFF7B72),
                title: strings.t('expenses'),
                subtitle: strings.t('trackSpendAndWithdrawals'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openScreen(const ExpenseScreen());
                },
              ),
              const SizedBox(height: 12),
              _SheetActionTile(
                icon: Icons.build_circle_outlined,
                color: const Color(0xFF6FA8FF),
                title: strings.t('services'),
                subtitle: strings.t('serviceShortHint'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openScreen(const ServiceScreen());
                },
              ),
              const SizedBox(height: 12),
              _SheetActionTile(
                icon: Icons.group_outlined,
                color: const Color(0xFFA78BFA),
                title: strings.t('staff'),
                subtitle: strings.t('createManageAccess'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openScreen(const StaffScreen());
                },
              ),
              const SizedBox(height: 12),
              _SheetActionTile(
                icon: Icons.logout_rounded,
                color: Theme.of(context).colorScheme.primary,
                title: strings.t('logout'),
                subtitle: strings.t('safeSignOutHint'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<ShopAuthProvider>().logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ShopAuthProvider>();
    final user = auth.userModel;
    final strings = context.strings;

    return Scaffold(
      extendBody: true,
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
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings),
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
              final isNarrowPhone = constraints.maxWidth < 460;
              final isWide = constraints.maxWidth > 920;
              final statCrossAxisCount = isWide
                  ? 4
                  : isNarrowPhone
                  ? 1
                  : 2;
              final statCardHeight = isWide
                  ? 168.0
                  : isNarrowPhone
                  ? 150.0
                  : 188.0;

              final statsGrid = GridView(
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
                      summary.operatingExpenses + summary.withdrawalExpenses,
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
              );

              final detailPanels = isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _TopSellersPanel(summary: summary)),
                        const SizedBox(width: 18),
                        Expanded(child: _LowStockPanel(summary: summary)),
                      ],
                    )
                  : Column(
                      children: [
                        _TopSellersPanel(summary: summary),
                        const SizedBox(height: 18),
                        _LowStockPanel(summary: summary),
                      ],
                    );

              return Stack(
                children: [
                  RepaintBoundary(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 132),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroCard(user: user, summary: summary),
                          const SizedBox(height: 18),
                          statsGrid,
                          const SizedBox(height: 22),
                          detailPanels,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: RepaintBoundary(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _dockVisible,
                        builder: (context, showDock, child) {
                          return SafeArea(
                            top: false,
                            child: IgnorePointer(
                              ignoring: !showDock,
                              child: AnimatedSlide(
                                offset: showDock
                                    ? Offset.zero
                                    : const Offset(0, 1.6),
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                child: AnimatedOpacity(
                                  opacity: showDock ? 1 : 0,
                                  duration: const Duration(milliseconds: 180),
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        child: BottomDockBar(
                          items: [
                            BottomDockItemData(
                              icon: Icons.dashboard_rounded,
                              label: strings.t('dockHome'),
                              active: true,
                              color: Theme.of(context).colorScheme.primary,
                              onTap: () {},
                            ),
                            BottomDockItemData(
                              icon: Icons.inventory_2_rounded,
                              label: strings.t('dockStock'),
                              active: false,
                              color: const Color(0xFF6FA8FF),
                              onTap: _showStockSheet,
                            ),
                            BottomDockItemData(
                              icon: Icons.point_of_sale_rounded,
                              label: strings.t('pos'),
                              active: false,
                              color: Theme.of(context).colorScheme.primary,
                              onTap: () => _openScreen(
                                PosScreen(title: strings.t('ownerPos')),
                              ),
                            ),
                            BottomDockItemData(
                              icon: Icons.insights_rounded,
                              label: strings.t('reports'),
                              active: false,
                              color: AppTheme.success,
                              onTap: () => _openScreen(const ReportsScreen()),
                            ),
                            BottomDockItemData(
                              icon: Icons.widgets_rounded,
                              label: strings.t('dockMore'),
                              active: false,
                              color: const Color(0xFFA78BFA),
                              onTap: _showMoreSheet,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SheetScaffold({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FastMoneyScreen()),
                );
              },
              icon: const Icon(Icons.flash_on_rounded),
              label: Text(strings.t('fastMoney')),
            ),
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
                        const SizedBox(width: 12),
                        Flexible(child: StockBadge(product: product)),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}
