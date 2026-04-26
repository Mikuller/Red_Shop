import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class RestockScreen extends StatefulWidget {
  final String? initialProductId;

  const RestockScreen({super.key, this.initialProductId});

  @override
  State<RestockScreen> createState() => _RestockScreenState();
}

class _RestockScreenState extends State<RestockScreen> {
  final ShopService _shopService = ShopService();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final List<PurchaseItem> _items = [];
  bool _isSaving = false;

  Future<void> _showAddItemDialog(List<Product> products) async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create products before recording restocks.'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final unitCostController = TextEditingController();
    var selectedProductId = widget.initialProductId ?? products.first.id;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add purchase item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProductId,
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: products
                        .map(
                          (product) => DropdownMenuItem(
                            value: product.id,
                            child: Text(product.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => selectedProductId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (value) {
                      final quantity = int.tryParse(value ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Enter a valid quantity.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: unitCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Unit cost'),
                    validator: (value) {
                      final unitCost = double.tryParse(value ?? '');
                      if (unitCost == null || unitCost < 0) {
                        return 'Enter a valid unit cost.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final product = products.firstWhere(
                        (item) => item.id == selectedProductId,
                      );
                      final quantity =
                          int.tryParse(quantityController.text.trim()) ?? 0;
                      final unitCost =
                          double.tryParse(unitCostController.text.trim()) ?? 0;
                      final existingIndex = _items.indexWhere(
                        (item) => item.productId == product.id,
                      );

                      setState(() {
                        if (existingIndex == -1) {
                          _items.add(
                            PurchaseItem(
                              productId: product.id,
                              productName: product.name,
                              quantity: quantity,
                              unitCost: unitCost,
                            ),
                          );
                        } else {
                          final current = _items[existingIndex];
                          final totalQuantity = current.quantity + quantity;
                          final blendedUnitCost =
                              (current.lineTotal + (quantity * unitCost)) /
                              totalQuantity;
                          _items[existingIndex] = PurchaseItem(
                            productId: current.productId,
                            productName: current.productName,
                            quantity: totalQuantity,
                            unitCost: blendedUnitCost,
                          );
                        }
                      });

                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Add item'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _recordPurchase(UserModel actor) async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item first.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _shopService.recordPurchase(
        items: _items,
        actor: actor,
        supplier: _supplierController.text.trim(),
        note: _noteController.text.trim(),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _items.clear();
        _supplierController.clear();
        _noteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restock purchase recorded.')),
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actor = context.watch<ShopAuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Restocking')),
      body: StreamBuilder<List<Product>>(
        stream: _shopService.watchProducts(),
        builder: (context, productSnapshot) {
          if (productSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = productSnapshot.data ?? <Product>[];
          final totalCost = _items.fold<double>(
            0,
            (sum, item) => sum + item.lineTotal,
          );

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
                        'New purchase',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _supplierController,
                        decoration: const InputDecoration(
                          labelText: 'Supplier or source',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _noteController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Note or invoice details',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showAddItemDialog(products),
                              icon: const Icon(Icons.add),
                              label: const Text('Add item'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving || actor == null
                                  ? null
                                  : () => _recordPurchase(actor),
                              icon: _isSaving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Record'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SummaryRow(
                        label: 'Current purchase total',
                        value: formatCurrency(totalCost),
                        emphasize: true,
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        const EmptyStateView(
                          icon: Icons.local_shipping_outlined,
                          title: 'No items in this purchase yet',
                          message: 'Add products with quantity and unit cost.',
                        )
                      else
                        ..._items.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.value.productName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${entry.value.quantity} pcs | ${formatCurrency(entry.value.unitCost)} each',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatCurrency(entry.value.lineTotal),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _items.removeAt(entry.key);
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Recent purchases',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<PurchaseRecord>>(
                  stream: _shopService.watchPurchases(),
                  builder: (context, purchaseSnapshot) {
                    if (purchaseSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final purchases =
                        purchaseSnapshot.data ?? <PurchaseRecord>[];
                    if (purchases.isEmpty) {
                      return const EmptyStateView(
                        icon: Icons.history_toggle_off_outlined,
                        title: 'No purchase history yet',
                        message:
                            'Recorded restocks will appear here with line-level cost details.',
                      );
                    }

                    return Column(
                      children: purchases.map((purchase) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppPanel(
                            padding: const EdgeInsets.all(0),
                            child: ExpansionTile(
                              title: Text(
                                purchase.supplier.isEmpty
                                    ? 'Purchase ${purchase.id.substring(0, 6)}'
                                    : purchase.supplier,
                              ),
                              subtitle: Text(
                                '${formatDateTime(purchase.createdAt)} | ${formatCurrency(purchase.totalCost)}',
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                18,
                                0,
                                18,
                                18,
                              ),
                              children: [
                                if (purchase.note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        purchase.note,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ),
                                ...purchase.items.map(
                                  (item) => SummaryRow(
                                    label:
                                        '${item.productName} | ${item.quantity} pcs',
                                    value: formatCurrency(item.lineTotal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
