import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

enum _PosCompactView { products, cart }

class PosScreen extends StatefulWidget {
  final String title;
  final bool showAppBar;

  const PosScreen({super.key, required this.title, this.showAppBar = true});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ShopService _shopService = ShopService();
  final List<_CartEntry> _cart = [];
  String _query = '';
  bool _isSubmitting = false;
  _PosCompactView _compactView = _PosCompactView.products;

  void _addToCart(Product product) {
    final strings = context.readStrings;
    final existingIndex = _cart.indexWhere(
      (entry) => entry.product.id == product.id,
    );
    final currentQuantity = existingIndex == -1
        ? 0
        : _cart[existingIndex].quantity;

    if (currentQuantity >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.t('noMoreStock', {'name': product.name})),
        ),
      );
      return;
    }

    setState(() {
      if (existingIndex == -1) {
        _cart.add(
          _CartEntry(
            product: product,
            quantity: 1,
            unitPrice: product.suggestedSellingPrice,
          ),
        );
      } else {
        _cart[existingIndex] = _cart[existingIndex].copyWith(
          quantity: _cart[existingIndex].quantity + 1,
        );
      }
    });
  }

  void _changeQuantity(_CartEntry entry, int delta) {
    final strings = context.readStrings;
    final nextQuantity = entry.quantity + delta;
    if (nextQuantity <= 0) {
      setState(() {
        _cart.removeWhere((item) => item.product.id == entry.product.id);
      });
      return;
    }

    if (nextQuantity > entry.product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.t('onlyUnitsLeft', {
              'name': entry.product.name,
              'count': '${entry.product.stock}',
            }),
          ),
        ),
      );
      return;
    }

    setState(() {
      final index = _cart.indexWhere(
        (item) => item.product.id == entry.product.id,
      );
      _cart[index] = entry.copyWith(quantity: nextQuantity);
    });
  }

  Future<void> _editPrice(_CartEntry entry) async {
    final strings = context.readStrings;
    final controller = TextEditingController(
      text: entry.unitPrice.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('setPriceFor', {'name': entry.product.name})),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: strings.t('sellingPrice')),
            validator: (value) {
              final price = double.tryParse(value ?? '');
              if (price == null || price <= 0) {
                return strings.t('validPrice');
              }

              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(double.parse(controller.text.trim()));
              }
            },
            child: Text(strings.t('update')),
          ),
        ],
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      final index = _cart.indexWhere(
        (item) => item.product.id == entry.product.id,
      );
      _cart[index] = entry.copyWith(unitPrice: result);
    });
  }

  Future<void> _checkout(UserModel actor) async {
    final strings = context.readStrings;
    if (_cart.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _shopService.recordSale(
        actor: actor,
        items: _cart
            .map(
              (entry) => SaleDraftItem(
                productId: entry.product.id,
                productName: entry.product.name,
                quantity: entry.quantity,
                unitPrice: entry.unitPrice,
              ),
            )
            .toList(),
      );
      if (!mounted) {
        return;
      }

      final total = _cart.fold<double>(0, (sum, item) => sum + item.lineTotal);
      setState(() {
        _cart.clear();
        _compactView = _PosCompactView.products;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.t('saleDoneFor', {'amount': formatCurrency(total)}),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(describeError(error))));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildSummaryStrip({
    required AppLocalizer strings,
    required double subtotal,
    required double estimatedProfit,
    required bool compact,
  }) {
    return AppPanel(
      child: compact
          ? Column(
              children: [
                SummaryRow(
                  label: strings.t('cartTotal'),
                  value: formatCurrency(subtotal),
                  emphasize: true,
                ),
                const Divider(height: 18),
                SummaryRow(
                  label: strings.t('estimatedProfit'),
                  value: formatCurrency(estimatedProfit),
                  emphasize: true,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: SummaryRow(
                    label: strings.t('cartTotal'),
                    value: formatCurrency(subtotal),
                    emphasize: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryRow(
                    label: strings.t('estimatedProfit'),
                    value: formatCurrency(estimatedProfit),
                    emphasize: true,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionSwitcher(BuildContext context, AppLocalizer strings) {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            selected: _compactView == _PosCompactView.products,
            icon: Icons.grid_view_rounded,
            label: strings.t('products'),
            onTap: () {
              setState(() => _compactView = _PosCompactView.products);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeChip(
            selected: _compactView == _PosCompactView.cart,
            icon: Icons.shopping_bag_outlined,
            label: strings.t('cart'),
            trailing: _cart.isEmpty ? null : '${_cart.length}',
            onTap: () {
              setState(() => _compactView = _PosCompactView.cart);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsView({
    required BuildContext context,
    required AppLocalizer strings,
    required List<Product> products,
    required List<Product> filtered,
    required double maxWidth,
    required bool compact,
  }) {
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: EmptyStateView(
          icon: Icons.point_of_sale_outlined,
          title: products.isEmpty
              ? strings.t('noProductsAvailable')
              : strings.t('noProductMatch'),
          message: products.isEmpty
              ? strings.t('addInventoryBeforePos')
              : strings.t('tryAnotherSearch'),
        ),
      );
    }

    final crossAxisCount = compact
        ? (maxWidth < 430 ? 1 : 2)
        : maxWidth > 900
        ? 4
        : 2;
    final cardHeight = compact
        ? (crossAxisCount == 1 ? 234.0 : 258.0)
        : 294.0;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: cardHeight,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        return _ProductTile(
          product: product,
          strings: strings,
          compact: compact,
          onAdd: product.stock > 0 ? () => _addToCart(product) : null,
        );
      },
    );
  }

  Widget _buildCartPanel({
    required BuildContext context,
    required AppLocalizer strings,
    required UserModel? actor,
    required double subtotal,
    required double estimatedProfit,
    required bool compact,
    required bool clampListHeight,
  }) {
    final cartList = _cart.isEmpty
        ? Text(
            strings.t('setPricesBeforeCheckout'),
            style: Theme.of(context).textTheme.bodyMedium,
          )
        : clampListHeight
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.min(280, 110.0 * _cart.length),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _cart.length,
              separatorBuilder: (_, _) => const Divider(height: 18),
              itemBuilder: (context, index) {
                final entry = _cart[index];
                return _CartEntryTile(
                  entry: entry,
                  compact: compact,
                  onDecrease: () => _changeQuantity(entry, -1),
                  onIncrease: () => _changeQuantity(entry, 1),
                  onEditPrice: () => _editPrice(entry),
                  onDelete: () {
                    setState(() {
                      _cart.removeAt(index);
                    });
                  },
                );
              },
            ),
          )
        : Column(
            children: [
              for (var index = 0; index < _cart.length; index++) ...[
                if (index > 0) const Divider(height: 18),
                _CartEntryTile(
                  entry: _cart[index],
                  compact: compact,
                  onDecrease: () => _changeQuantity(_cart[index], -1),
                  onIncrease: () => _changeQuantity(_cart[index], 1),
                  onEditPrice: () => _editPrice(_cart[index]),
                  onDelete: () {
                    setState(() {
                      _cart.removeAt(index);
                    });
                  },
                ),
              ],
            ],
          );

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                strings.t('cart'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                strings.t('itemCountShort', {'count': '${_cart.length}'}),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          cartList,
          const SizedBox(height: 14),
          SummaryRow(
            label: strings.t('subtotal'),
            value: formatCurrency(subtotal),
            emphasize: true,
          ),
          SummaryRow(
            label: strings.t('estimatedProfit'),
            value: formatCurrency(estimatedProfit),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cart.isEmpty || actor == null || _isSubmitting
                  ? null
                  : () => _checkout(actor),
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(strings.t('checkout')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCartDock(
    BuildContext context,
    AppLocalizer strings,
    double subtotal,
  ) {
    return AppPanel(
      onTap: () {
        setState(() => _compactView = _PosCompactView.cart);
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              strings.t('itemCountShort', {'count': '${_cart.length}'}),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('viewCart'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  formatCurrency(subtotal),
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

  @override
  Widget build(BuildContext context) {
    final actor = context.watch<ShopAuthProvider>().userModel;
    final strings = context.strings;
    final subtotal = _cart.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final estimatedProfit = _cart.fold<double>(
      0,
      (sum, item) =>
          sum + ((item.unitPrice - item.product.averageCost) * item.quantity),
    );

    final content = StreamBuilder<List<Product>>(
      stream: _shopService.watchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? <Product>[];
        final filtered = products.where((product) {
          return _query.isEmpty ||
              product.name.toLowerCase().contains(_query.toLowerCase()) ||
              product.category.toLowerCase().contains(_query.toLowerCase()) ||
              product.sku.toLowerCase().contains(_query.toLowerCase());
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        decoration: InputDecoration(
                          hintText: strings.t('searchProductShort'),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryStrip(
                        strings: strings,
                        subtotal: subtotal,
                        estimatedProfit: estimatedProfit,
                        compact: compact,
                      ),
                      if (compact) ...[
                        const SizedBox(height: 12),
                        _buildSectionSwitcher(context, strings),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: compact
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _compactView == _PosCompactView.products
                              ? _buildProductsView(
                                  context: context,
                                  strings: strings,
                                  products: products,
                                  filtered: filtered,
                                  maxWidth: constraints.maxWidth,
                                  compact: true,
                                )
                              : SingleChildScrollView(
                                  key: const ValueKey('cart-view'),
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    20,
                                  ),
                                  child: _buildCartPanel(
                                    context: context,
                                    strings: strings,
                                    actor: actor,
                                    subtotal: subtotal,
                                    estimatedProfit: estimatedProfit,
                                    compact: true,
                                    clampListHeight: false,
                                  ),
                                ),
                        )
                      : _buildProductsView(
                          context: context,
                          strings: strings,
                          products: products,
                          filtered: filtered,
                          maxWidth: constraints.maxWidth,
                          compact: false,
                        ),
                ),
                if (!compact)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: _buildCartPanel(
                        context: context,
                        strings: strings,
                        actor: actor,
                        subtotal: subtotal,
                        estimatedProfit: estimatedProfit,
                        compact: false,
                        clampListHeight: true,
                      ),
                    ),
                  )
                else if (_compactView == _PosCompactView.products &&
                    _cart.isNotEmpty)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: _buildMiniCartDock(context, strings, subtotal),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [LanguageMenuButton()],
      ),
      body: content,
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final AppLocalizer strings;
  final bool compact;
  final VoidCallback? onAdd;

  const _ProductTile({
    required this.product,
    required this.strings,
    required this.compact,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: compact ? 18 : 20,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(16),
                child: Icon(
                  Icons.computer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: compact ? 18 : 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: StockBadge(product: product)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            product.category.isEmpty
                ? strings.t('uncategorized')
                : product.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            strings.t('suggested', {
              'amount': formatCurrency(product.suggestedSellingPrice),
            }),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdd,
              child: Text(strings.t('addToCart')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartEntryTile extends StatelessWidget {
  final _CartEntry entry;
  final bool compact;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEditPrice;
  final VoidCallback onDelete;

  const _CartEntryTile({
    required this.entry,
    required this.compact,
    required this.onDecrease,
    required this.onIncrease,
    required this.onEditPrice,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _QuantityButton(icon: Icons.remove, onTap: onDecrease),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            '${entry.quantity}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        _QuantityButton(icon: Icons.add, onTap: onIncrease),
        OutlinedButton.icon(
          onPressed: onEditPrice,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(formatCurrency(entry.unitPrice)),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatCurrency(entry.lineTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          controls,
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              controls,
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(entry.lineTotal),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _ModeChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : AppTheme.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(18) : AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color.withAlpha(90) : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trailing!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _CartEntry {
  final Product product;
  final int quantity;
  final double unitPrice;

  const _CartEntry({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  _CartEntry copyWith({Product? product, int? quantity, double? unitPrice}) {
    return _CartEntry(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  double get lineTotal => quantity * unitPrice;
}
