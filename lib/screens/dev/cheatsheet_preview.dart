import 'package:flutter/material.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

enum CheatsheetPreviewMode { login, ownerDashboard, ownerInventory, clerkPos }

CheatsheetPreviewMode? cheatsheetPreviewModeFromUri(Uri uri) {
  switch (uri.queryParameters['preview']) {
    case 'login':
      return CheatsheetPreviewMode.login;
    case 'owner-dashboard':
      return CheatsheetPreviewMode.ownerDashboard;
    case 'owner-inventory':
      return CheatsheetPreviewMode.ownerInventory;
    case 'clerk-pos':
      return CheatsheetPreviewMode.clerkPos;
    default:
      return null;
  }
}

class CheatsheetPreviewScreen extends StatelessWidget {
  final CheatsheetPreviewMode mode;

  const CheatsheetPreviewScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case CheatsheetPreviewMode.login:
        return const _LoginPreview();
      case CheatsheetPreviewMode.ownerDashboard:
        return const _OwnerDashboardPreview();
      case CheatsheetPreviewMode.ownerInventory:
        return const _OwnerInventoryPreview();
      case CheatsheetPreviewMode.clerkPos:
        return const _ClerkPosPreview();
    }
  }
}

class _LoginPreview extends StatelessWidget {
  const _LoginPreview();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.border),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            context.languageController.language ==
                                    AppLanguage.amharic
                                ? 'አማ'
                                : 'EN',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Icon(
                    Icons.laptop_mac_outlined,
                    size: 70,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    strings.t('appName'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.t('shopLogin'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('login'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          decoration: InputDecoration(
                            labelText: strings.t('email'),
                            prefixIcon: const Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: strings.t('password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: const Icon(
                              Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            strings.t('forgotPassword'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _noop,
                            child: Text(strings.t('login')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerDashboardPreview extends StatelessWidget {
  const _OwnerDashboardPreview();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('appName')),
            Text(
              'myko',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: const [
          LanguageMenuButton(),
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.point_of_sale_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                    strings.t('welcomeBack', {'name': 'myko'}),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.t('todaySummary', {
                      'count': '7',
                      'amount': formatCurrency(18500),
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
                        value: formatCurrency(6200),
                        hint: strings.t('tapToOpen'),
                      ),
                      HeroMetricBadge(
                        icon: Icons.warning_amber_rounded,
                        label: strings.t('lowStock'),
                        value: strings.t('itemCountShort', {'count': '3'}),
                        hint: strings.t('tapToOpen'),
                      ),
                      HeroMetricBadge(
                        icon: Icons.shopping_bag_outlined,
                        label: strings.t('restocks'),
                        value: formatCurrency(24000),
                        hint: strings.t('tapToOpen'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 196,
              ),
              children: const [
                DashboardStatCard(
                  title: 'Money in',
                  value: 'ETB 48,500.00',
                  subtitle: '16 sales done',
                  icon: Icons.payments_outlined,
                  color: AppTheme.success,
                ),
                DashboardStatCard(
                  title: 'Profit',
                  value: 'ETB 12,300.00',
                  subtitle: 'Before shop costs',
                  icon: Icons.trending_up_outlined,
                  color: Color(0xFFE92C47),
                ),
                DashboardStatCard(
                  title: 'Costs',
                  value: 'ETB 3,450.00',
                  subtitle: 'Shop costs + take-outs',
                  icon: Icons.receipt_long_outlined,
                  color: AppTheme.warning,
                ),
                DashboardStatCard(
                  title: 'Stock value',
                  value: 'ETB 126,000.00',
                  subtitle: '37 items in stock',
                  icon: Icons.inventory_2_outlined,
                  color: Color(0xFF6FA8FF),
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 188,
              ),
              children: const [
                ActionShortcutCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory',
                  subtitle: 'Products and stock',
                  hint: 'Tap to open',
                  color: Color(0xFF6FA8FF),
                  onTap: _noop,
                ),
                ActionShortcutCard(
                  icon: Icons.local_shipping_outlined,
                  title: 'Restocking',
                  subtitle: 'Record new stock',
                  hint: 'Tap to open',
                  color: AppTheme.warning,
                  onTap: _noop,
                ),
                ActionShortcutCard(
                  icon: Icons.point_of_sale_outlined,
                  title: 'POS',
                  subtitle: 'Start a sale',
                  hint: 'Tap to open',
                  color: Color(0xFFE92C47),
                  onTap: _noop,
                ),
                ActionShortcutCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Expenses',
                  subtitle: 'Track spend and withdrawals',
                  hint: 'Tap to open',
                  color: Color(0xFFFF7B72),
                  onTap: _noop,
                ),
                ActionShortcutCard(
                  icon: Icons.bar_chart_outlined,
                  title: 'Reports',
                  subtitle: 'Profit and best sellers',
                  hint: 'Tap to open',
                  color: AppTheme.success,
                  onTap: _noop,
                ),
                ActionShortcutCard(
                  icon: Icons.group_outlined,
                  title: 'Staff',
                  subtitle: 'Create and manage access',
                  hint: 'Tap to open',
                  color: Color(0xFFA78BFA),
                  onTap: _noop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerInventoryPreview extends StatelessWidget {
  const _OwnerInventoryPreview();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final products = [
      Product(
        id: '1',
        name: 'HP ProBook 440',
        category: 'Laptop',
        sku: 'LAP-440',
        description: '14-inch business laptop',
        imageUrl: '',
        suggestedSellingPrice: 42000,
        averageCost: 36000,
        stock: 2,
        lowStockThreshold: 3,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 4, 20),
      ),
      Product(
        id: '2',
        name: 'Dell USB Keyboard',
        category: 'Accessories',
        sku: 'KEY-DL',
        description: 'Full-size keyboard',
        imageUrl: '',
        suggestedSellingPrice: 950,
        averageCost: 640,
        stock: 9,
        lowStockThreshold: 4,
        createdAt: DateTime(2026, 1, 5),
        updatedAt: DateTime(2026, 4, 18),
      ),
      Product(
        id: '3',
        name: 'A4Tech Wireless Mouse',
        category: 'Accessories',
        sku: 'MSE-A4',
        description: 'Wireless mouse',
        imageUrl: '',
        suggestedSellingPrice: 1200,
        averageCost: 780,
        stock: 0,
        lowStockThreshold: 3,
        createdAt: DateTime(2026, 2, 3),
        updatedAt: DateTime(2026, 4, 25),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('inventory')),
        actions: const [LanguageMenuButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: strings.t('searchProducts'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilterChip(
                  label: Text(strings.t('lowStockOnly')),
                  selected: true,
                  onSelected: (_) {},
                ),
                const Spacer(),
                Text(
                  strings.t('productCount', {'count': '${products.length}'}),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _MiniSummaryCard(label: strings.t('unitsInStock'), value: '11'),
                const SizedBox(height: 12),
                _MiniSummaryCard(
                  label: strings.t('stockValue'),
                  value: formatCurrency(81120),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...products.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product.category} | ${product.sku}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.more_horiz),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          StockBadge(product: product),
                          Text(
                            'Cost ${formatCurrency(product.averageCost)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Suggested ${formatCurrency(product.suggestedSellingPrice)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Margin ${formatCurrency(product.marginPerUnit)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.t('recentPurchases'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Addis supplier',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SummaryRow(
                    label: 'HP ProBook 440 | 2 pcs',
                    value: formatCurrency(72000),
                  ),
                  SummaryRow(
                    label: 'Dell USB Keyboard | 6 pcs',
                    value: formatCurrency(3840),
                  ),
                  const Divider(height: 26),
                  SummaryRow(
                    label: strings.t('currentPurchaseTotal'),
                    value: formatCurrency(75840),
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClerkPosPreview extends StatelessWidget {
  const _ClerkPosPreview();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('salesPos')),
        actions: const [LanguageMenuButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: strings.t('searchProductShort'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            AppPanel(
              child: Row(
                children: [
                  Expanded(
                    child: SummaryRow(
                      label: strings.t('cartTotal'),
                      value: formatCurrency(39750),
                      emphasize: true,
                    ),
                  ),
                  Expanded(
                    child: SummaryRow(
                      label: strings.t('estimatedProfit'),
                      value: formatCurrency(5820),
                      emphasize: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 186,
              ),
              children: const [
                _ProductTile(
                  name: 'HP ProBook 440',
                  category: 'Laptop',
                  price: 'ETB 42,000.00',
                  stock: '2 left',
                ),
                _ProductTile(
                  name: 'A4Tech Mouse',
                  category: 'Accessory',
                  price: 'ETB 1,200.00',
                  stock: '8 left',
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('cartItems'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _CartPreviewRow(
                    name: 'HP ProBook 440',
                    price: 'ETB 38,500.00',
                    qty: '1',
                  ),
                  const Divider(height: 22),
                  const _CartPreviewRow(
                    name: 'A4Tech Mouse',
                    price: 'ETB 1,250.00',
                    qty: '1',
                  ),
                  const Divider(height: 22),
                  const _CartPreviewRow(
                    name: 'Dell USB Keyboard',
                    price: 'ETB 1,000.00',
                    qty: '1',
                  ),
                  const SizedBox(height: 12),
                  SummaryRow(
                    label: strings.t('cartTotal'),
                    value: formatCurrency(40750),
                    emphasize: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _noop,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(strings.t('completeSale')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final String name;
  final String category;
  final String price;
  final String stock;

  const _ProductTile({
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withAlpha(24),
            child: const Icon(Icons.devices_outlined, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(stock, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _MiniSummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPreviewRow extends StatelessWidget {
  final String name;
  final String price;
  final String qty;

  const _CartPreviewRow({
    required this.name,
    required this.price,
    required this.qty,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(price, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text('x$qty'),
        ),
      ],
    );
  }
}

void _noop() {}
