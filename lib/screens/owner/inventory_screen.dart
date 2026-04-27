import 'package:flutter/material.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/screens/owner/restock_screen.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class InventoryScreen extends StatefulWidget {
  final bool startLowStockOnly;

  const InventoryScreen({super.key, this.startLowStockOnly = false});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ShopService _shopService = ShopService();
  String _query = '';
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _showLowStockOnly = widget.startLowStockOnly;
  }

  Future<void> _showProductForm([Product? product]) async {
    final strings = context.readStrings;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?.name);
    final categoryController = TextEditingController(text: product?.category);
    final skuController = TextEditingController(text: product?.sku);
    final priceController = TextEditingController(
      text: product == null
          ? ''
          : product.suggestedSellingPrice.toStringAsFixed(2),
    );
    final lowStockController = TextEditingController(
      text: product?.lowStockThreshold.toString() ?? '3',
    );
    final descriptionController = TextEditingController(
      text: product?.description,
    );
    final imageController = TextEditingController(text: product?.imageUrl);
    final openingStockController = TextEditingController();
    final openingCostController = TextEditingController();
    var isSaving = false;

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
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product == null
                          ? strings.t('addProduct')
                          : strings.t('editProduct'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: strings.t('name')),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.t('nameRequired')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        labelText: strings.t('category'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: skuController,
                      decoration: InputDecoration(labelText: strings.t('sku')),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: strings.t('suggestedSellingPrice'),
                      ),
                      validator: (value) {
                        final price = double.tryParse(value ?? '');
                        if (price == null || price < 0) {
                          return strings.t('validPrice');
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: lowStockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: strings.t('lowStockThreshold'),
                      ),
                      validator: (value) {
                        final threshold = int.tryParse(value ?? '');
                        if (threshold == null || threshold < 0) {
                          return strings.t('validThreshold');
                        }

                        return null;
                      },
                    ),
                    if (product == null) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: openingStockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: strings.t('openingStock'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: openingCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: strings.t('openingUnitCost'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: strings.t('description'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: imageController,
                      decoration: InputDecoration(
                        labelText: strings.t('imageUrl'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              final openingStock =
                                  int.tryParse(
                                    openingStockController.text.trim(),
                                  ) ??
                                  0;
                              final openingCost =
                                  double.tryParse(
                                    openingCostController.text.trim(),
                                  ) ??
                                  0;
                              final now = DateTime.now();
                              final current =
                                  product ??
                                  Product(
                                    id: '',
                                    name: '',
                                    category: '',
                                    sku: '',
                                    description: '',
                                    imageUrl: '',
                                    suggestedSellingPrice: 0,
                                    averageCost: openingStock > 0
                                        ? openingCost
                                        : 0,
                                    stock: openingStock,
                                    lowStockThreshold: 3,
                                    createdAt: now,
                                    updatedAt: now,
                                  );

                              final updated = current.copyWith(
                                name: nameController.text.trim(),
                                category: categoryController.text.trim(),
                                sku: skuController.text.trim(),
                                description: descriptionController.text.trim(),
                                imageUrl: imageController.text.trim(),
                                suggestedSellingPrice:
                                    double.tryParse(
                                      priceController.text.trim(),
                                    ) ??
                                    0,
                                lowStockThreshold:
                                    int.tryParse(
                                      lowStockController.text.trim(),
                                    ) ??
                                    0,
                              );

                              final navigator = Navigator.of(sheetContext);
                              final messenger = ScaffoldMessenger.of(
                                this.context,
                              );
                              try {
                                setModalState(() => isSaving = true);
                                await _shopService.saveProduct(updated);
                                if (!mounted) {
                                  return;
                                }

                                navigator.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      product == null
                                          ? strings.t('productAdded')
                                          : strings.t('productUpdated'),
                                    ),
                                  ),
                                );
                              } catch (error) {
                                if (!mounted) {
                                  return;
                                }

                                messenger.showSnackBar(
                                  SnackBar(content: Text(describeError(error))),
                                );
                                setModalState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              product == null
                                  ? strings.t('saveProduct')
                                  : strings.t('saveChanges'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final strings = context.readStrings;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('deleteProduct')),
        content: Text(
          strings.t('deleteProductMessage', {'name': product.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _shopService.deleteProduct(product.id);
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(strings.t('productDeleted'))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(describeError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('inventory')),
        actions: [
          const LanguageMenuButton(),
          IconButton(
            tooltip: strings.t('addProduct'),
            onPressed: _showProductForm,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _shopService.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? <Product>[];
          final filtered = products.where((product) {
            final matchesQuery =
                _query.isEmpty ||
                product.name.toLowerCase().contains(_query.toLowerCase()) ||
                product.category.toLowerCase().contains(_query.toLowerCase()) ||
                product.sku.toLowerCase().contains(_query.toLowerCase());
            final matchesStock = !_showLowStockOnly || product.isLowStock;
            return matchesQuery && matchesStock;
          }).toList();
          final inventoryValue = filtered.fold<double>(
            0,
            (sum, product) => sum + (product.averageCost * product.stock),
          );
          final units = filtered.fold<int>(
            0,
            (sum, product) => sum + product.stock,
          );

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
                        hintText: strings.t('searchProducts'),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilterChip(
                          label: Text(strings.t('lowStockOnly')),
                          selected: _showLowStockOnly,
                          onSelected: (selected) =>
                              setState(() => _showLowStockOnly = selected),
                        ),
                        const Spacer(),
                        Text(
                          strings.t('productCount', {
                            'count': '${filtered.length}',
                          }),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppPanel(
                            child: SummaryRow(
                              label: strings.t('unitsInStock'),
                              value: '$units',
                              emphasize: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppPanel(
                            child: SummaryRow(
                              label: strings.t('stockValue'),
                              value: formatCurrency(inventoryValue),
                              emphasize: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: EmptyStateView(
                          icon: Icons.inventory_2_outlined,
                          title: products.isEmpty
                              ? strings.t('noProductsYet')
                              : strings.t('noFilterMatch'),
                          message: products.isEmpty
                              ? strings.t('createFirstProduct')
                              : strings.t('tryDifferentSearch'),
                          actionLabel: products.isEmpty
                              ? strings.t('addProduct')
                              : null,
                          onAction: products.isEmpty
                              ? () => _showProductForm()
                              : null,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return AppPanel(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InventoryImage(product: product),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              switch (value) {
                                                case 'edit':
                                                  _showProductForm(product);
                                                  break;
                                                case 'restock':
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          RestockScreen(
                                                            initialProductId:
                                                                product.id,
                                                          ),
                                                    ),
                                                  );
                                                  break;
                                                case 'delete':
                                                  _confirmDelete(product);
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text(strings.t('edit')),
                                              ),
                                              PopupMenuItem(
                                                value: 'restock',
                                                child: Text(
                                                  strings.t('restock'),
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text(
                                                  strings.t('delete'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        product.category.isEmpty
                                            ? strings.t('uncategorized')
                                            : product.category,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      if (product.sku.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'SKU: ${product.sku}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 10,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          StockBadge(product: product),
                                          Text(
                                            strings.t('cost', {
                                              'amount': formatCurrency(
                                                product.averageCost,
                                              ),
                                            }),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          Text(
                                            strings.t('suggested', {
                                              'amount': formatCurrency(
                                                product.suggestedSellingPrice,
                                              ),
                                            }),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          Text(
                                            strings.t('margin', {
                                              'amount': formatCurrency(
                                                product.marginPerUnit,
                                              ),
                                            }),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      product.marginPerUnit >= 0
                                                      ? AppTheme.success
                                                      : const Color(0xFFE65D5D),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showProductForm,
        icon: const Icon(Icons.add),
        label: Text(strings.t('product')),
      ),
    );
  }
}

class _InventoryImage extends StatelessWidget {
  final Product product;

  const _InventoryImage({required this.product});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    if (product.imageUrl.trim().isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: borderRadius,
        ),
        child: const Icon(Icons.computer_outlined),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        product.imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 72,
          height: 72,
          color: AppTheme.surfaceAlt,
          child: const Icon(Icons.computer_outlined),
        ),
      ),
    );
  }
}
