import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

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

  void _addToCart(Product product) {
    final existingIndex = _cart.indexWhere(
      (entry) => entry.product.id == product.id,
    );
    final currentQuantity = existingIndex == -1
        ? 0
        : _cart[existingIndex].quantity;

    if (currentQuantity >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} has no more stock available.')),
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
            '${entry.product.name} only has ${entry.product.stock} units in stock.',
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
    final controller = TextEditingController(
      text: entry.unitPrice.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set price for ${entry.product.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Selling price'),
            validator: (value) {
              final price = double.tryParse(value ?? '');
              if (price == null || price <= 0) {
                return 'Enter a valid selling price.';
              }

              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(double.parse(controller.text.trim()));
              }
            },
            child: const Text('Update'),
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
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale completed for ${formatCurrency(total)}.')),
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

  @override
  Widget build(BuildContext context) {
    final actor = context.watch<ShopAuthProvider>().userModel;
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPanel(
                    child: Row(
                      children: [
                        Expanded(
                          child: SummaryRow(
                            label: 'Cart total',
                            value: formatCurrency(subtotal),
                            emphasize: true,
                          ),
                        ),
                        Expanded(
                          child: SummaryRow(
                            label: 'Est. profit',
                            value: formatCurrency(estimatedProfit),
                            emphasize: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: EmptyStateView(
                        icon: Icons.point_of_sale_outlined,
                        title: products.isEmpty
                            ? 'No products available'
                            : 'No products matched',
                        message: products.isEmpty
                            ? 'Add inventory before opening the POS.'
                            : 'Try another search term.',
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 900
                            ? 4
                            : 2;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.86,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return AppPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: product.imageUrl.trim().isEmpty
                                          ? const Icon(
                                              Icons.computer_outlined,
                                              size: 48,
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: Image.network(
                                                product.imageUrl,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(
                                                      Icons.computer_outlined,
                                                      size: 48,
                                                    ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    product.category.isEmpty
                                        ? 'Uncategorized'
                                        : product.category,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  StockBadge(product: product),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Suggested ${formatCurrency(product.suggestedSellingPrice)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const Spacer(),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: product.stock > 0
                                          ? () => _addToCart(product)
                                          : null,
                                      child: const Text('Add to cart'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Cart',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Text(
                            '${_cart.length} item${_cart.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_cart.isEmpty)
                        Text(
                          'Add products and set sale prices here before checkout.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: math.min(260, 90.0 * _cart.length),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _cart.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 18),
                            itemBuilder: (context, index) {
                              final entry = _cart[index];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.product.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  _changeQuantity(entry, -1),
                                              icon: const Icon(Icons.remove),
                                            ),
                                            Text('${entry.quantity}'),
                                            IconButton(
                                              onPressed: () =>
                                                  _changeQuantity(entry, 1),
                                              icon: const Icon(Icons.add),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _editPrice(entry),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              label: Text(
                                                formatCurrency(entry.unitPrice),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatCurrency(entry.lineTotal),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _cart.removeAt(index);
                                          });
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 14),
                      SummaryRow(
                        label: 'Subtotal',
                        value: formatCurrency(subtotal),
                        emphasize: true,
                      ),
                      SummaryRow(
                        label: 'Estimated profit',
                        value: formatCurrency(estimatedProfit),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _cart.isEmpty || actor == null || _isSubmitting
                              ? null
                              : () => _checkout(actor),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Checkout'),
                        ),
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

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: content,
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
