import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

enum _ServiceCostMode { none, cash, sparePart }

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final ShopService _shopService = ShopService();
  List<Product> _latestProducts = const <Product>[];
  ServiceStatus? _filterStatus;

  Future<void> _showServiceForm(List<Product> products, UserModel actor) async {
    final strings = context.readStrings;
    final partCatalog = products.where((product) => product.stock > 0).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final formKey = GlobalKey<FormState>();
    final serviceTypeController = TextEditingController();
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();
    final serviceChargeController = TextEditingController();
    final cashCostController = TextEditingController();
    final sparePartQuantityController = TextEditingController(text: '1');
    final noteController = TextEditingController();
    final sparePartSearchController = TextEditingController();
    var isSaving = false;
    var costMode = _ServiceCostMode.none;
    var status = ServiceStatus.pending;
    var selectedCategory = null as String?;
    var selectedPartId = partCatalog.isEmpty ? null : partCatalog.first.id;
    var partQuery = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceAlt,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final categoryOptions = collectProductCategories(
            partCatalog,
            includeUncategorized: true,
          );
          final filteredParts = partCatalog.where((product) {
            final normalizedQuery = partQuery.toLowerCase();
            final matchesQuery =
                normalizedQuery.isEmpty ||
                product.name.toLowerCase().contains(normalizedQuery) ||
                product.category.toLowerCase().contains(normalizedQuery) ||
                product.sku.toLowerCase().contains(normalizedQuery);
            final matchesCategory = selectedCategory == null
                ? true
                : selectedCategory!.isEmpty
                ? product.category.trim().isEmpty
                : product.category.toLowerCase() ==
                      selectedCategory!.toLowerCase();
            return matchesQuery && matchesCategory;
          }).toList();
          final effectivePartId = filteredParts.any(
            (product) => product.id == selectedPartId,
          )
              ? selectedPartId
              : filteredParts.isEmpty
              ? null
              : filteredParts.first.id;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: AbsorbPointer(
                absorbing: isSaving,
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Text(
                      strings.t('addServiceJob'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: serviceTypeController,
                      decoration: InputDecoration(
                        labelText: strings.t('serviceType'),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.t('serviceTypeRequired')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: customerNameController,
                      decoration: InputDecoration(
                        labelText: strings.t('customerName'),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.t('customerNameRequired')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: customerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: strings.t('customerPhone'),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.t('customerPhoneRequired')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: serviceChargeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: strings.t('serviceCharge'),
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount < 0) {
                          return strings.t('validAmount');
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<ServiceStatus>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: strings.t('serviceStatus'),
                      ),
                      items: ServiceStatus.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(strings.serviceStatusLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      strings.t('maintenanceCost'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CostModeChip(
                          selected: costMode == _ServiceCostMode.none,
                          label: strings.t('noCost'),
                          onTap: () {
                            setModalState(() => costMode = _ServiceCostMode.none);
                          },
                        ),
                        _CostModeChip(
                          selected: costMode == _ServiceCostMode.cash,
                          label: strings.t('cashCost'),
                          onTap: () {
                            setModalState(() => costMode = _ServiceCostMode.cash);
                          },
                        ),
                        _CostModeChip(
                          selected: costMode == _ServiceCostMode.sparePart,
                          label: strings.t('sparePartFromStock'),
                          onTap: () {
                            setModalState(
                              () => costMode = _ServiceCostMode.sparePart,
                            );
                          },
                        ),
                      ],
                    ),
                    if (costMode == _ServiceCostMode.cash) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: cashCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: strings.t('cashCost'),
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount < 0) {
                            return strings.t('validAmount');
                          }

                          return null;
                        },
                      ),
                    ],
                    if (costMode == _ServiceCostMode.sparePart) ...[
                      const SizedBox(height: 14),
                      if (partCatalog.isEmpty)
                        EmptyStateView(
                          icon: Icons.build_circle_outlined,
                          title: strings.t('noSparePartsAvailable'),
                          message: strings.t('addInventoryBeforeServiceParts'),
                        )
                      else ...[
                        TextField(
                          controller: sparePartSearchController,
                          onChanged: (value) {
                            setModalState(() => partQuery = value.trim());
                          },
                          decoration: InputDecoration(
                            hintText: strings.t('searchSpareParts'),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CategoryFilterBar(
                          categories: categoryOptions,
                          selectedCategory: selectedCategory,
                          allLabel: strings.t('allCategories'),
                          uncategorizedLabel: strings.t('uncategorized'),
                          onSelected: (value) {
                            setModalState(() => selectedCategory = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: filteredParts.isEmpty
                              ? EmptyStateView(
                                  icon: Icons.search_off_rounded,
                                  title: strings.t('noProductMatch'),
                                  message: strings.t('noProductsInCategory'),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filteredParts.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final product = filteredParts[index];
                                    return _ServicePartTile(
                                      product: product,
                                      strings: strings,
                                      selected: product.id == effectivePartId,
                                      onTap: () {
                                        setModalState(
                                          () => selectedPartId = product.id,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: sparePartQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.t('quantityUsed'),
                          ),
                          validator: (value) {
                            final quantity = int.tryParse(value ?? '');
                            if (quantity == null || quantity <= 0) {
                              return strings.t('validQuantity');
                            }

                            return null;
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: strings.t('serviceNote'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                        if (!formKey.currentState!.validate()) {
                          setModalState(() => isSaving = false);
                          return;
                        }

                        if (costMode == _ServiceCostMode.sparePart &&
                            effectivePartId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.t('chooseSparePart')),
                            ),
                          );
                          setModalState(() => isSaving = false);
                          return;
                        }

                        final sparePart = effectivePartId == null
                            ? null
                            : partCatalog.firstWhere(
                                (product) => product.id == effectivePartId,
                              );
                        final quantity =
                            int.tryParse(
                              sparePartQuantityController.text.trim(),
                            ) ??
                            0;

                        try {
                          await _shopService.createService(
                            ServiceRecord(
                              id: '',
                              serviceType: serviceTypeController.text.trim(),
                              customerName: customerNameController.text.trim(),
                              customerPhone: customerPhoneController.text.trim(),
                              serviceCharge:
                                  double.tryParse(
                                    serviceChargeController.text.trim(),
                                  ) ??
                                  0,
                              status: status,
                              cashCost: costMode == _ServiceCostMode.cash
                                  ? double.tryParse(
                                        cashCostController.text.trim(),
                                      ) ??
                                      0
                                  : 0,
                              sparePartProductId:
                                  costMode == _ServiceCostMode.sparePart
                                  ? sparePart?.id ?? ''
                                  : '',
                              sparePartProductName:
                                  costMode == _ServiceCostMode.sparePart
                                  ? sparePart?.name ?? ''
                                  : '',
                              sparePartQuantity:
                                  costMode == _ServiceCostMode.sparePart
                                  ? quantity
                                  : 0,
                              sparePartUnitCost:
                                  costMode == _ServiceCostMode.sparePart
                                  ? sparePart?.averageCost ?? 0
                                  : 0,
                              note: noteController.text.trim(),
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                              createdByUid: actor.uid,
                              createdByName: actor.name,
                            ),
                          );
                           if (!sheetContext.mounted) {
                             return;
                           }
                           Navigator.of(sheetContext).pop();
                           if (!mounted) {
                             return;
                           }
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text(strings.t('serviceSaved')),
                             ),
                           );
                         } catch (error) {
                           if (!mounted) {
                             return;
                           }
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(describeError(error))),
                           );
                         } finally {
                           if (sheetContext.mounted) {
                             setModalState(() => isSaving = false);
                           }
                         }

                      },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.t('saveServiceJob')),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return AppTheme.warning;
      case ServiceStatus.completedUnpaid:
        return const Color(0xFF6FA8FF);
      case ServiceStatus.completedPaid:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = context.watch<ShopAuthProvider>().userModel;
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('services')),
        actions: [
          const LanguageMenuButton(),
          if (actor != null)
            IconButton(
              tooltip: strings.t('addServiceJob'),
              onPressed: () => _showServiceForm(_latestProducts, actor),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _shopService.watchProducts(),
        builder: (context, productSnapshot) {
          if (productSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = productSnapshot.data ?? <Product>[];
          _latestProducts = products;
          return StreamBuilder<List<ServiceRecord>>(
            stream: _shopService.watchServices(),
            builder: (context, serviceSnapshot) {
              if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final services = serviceSnapshot.data ?? <ServiceRecord>[];
              final filtered = _filterStatus == null
                  ? services
                  : services
                        .where((service) => service.status == _filterStatus)
                        .toList();
              final pendingCount = services
                  .where((service) => service.status == ServiceStatus.pending)
                  .length;
              final paidIncome = services
                  .where((service) => service.status == ServiceStatus.completedPaid)
                  .fold<double>(0, (sum, service) => sum + service.serviceCharge);
              final unpaidIncome = services
                  .where(
                    (service) =>
                        service.status == ServiceStatus.completedUnpaid,
                  )
                  .fold<double>(0, (sum, service) => sum + service.serviceCharge);
              final totalCost = services.fold<double>(
                0,
                (sum, service) => sum + service.totalCost,
              );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _ServiceSummaryCard(
                              label: strings.t('pendingServices'),
                              value: '$pendingCount',
                            ),
                            _ServiceSummaryCard(
                              label: strings.t('paidIncome'),
                              value: formatCurrency(paidIncome),
                            ),
                            _ServiceSummaryCard(
                              label: strings.t('unpaidIncome'),
                              value: formatCurrency(unpaidIncome),
                            ),
                            _ServiceSummaryCard(
                              label: strings.t('maintenanceCost'),
                              value: formatCurrency(totalCost),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: Text(strings.t('allStatuses')),
                              selected: _filterStatus == null,
                              onSelected: (_) {
                                setState(() => _filterStatus = null);
                              },
                            ),
                            ...ServiceStatus.values.map(
                              (status) => FilterChip(
                                label: Text(strings.serviceStatusLabel(status)),
                                selected: _filterStatus == status,
                                onSelected: (_) {
                                  setState(() => _filterStatus = status);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filtered.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                            children: [
                              EmptyStateView(
                              icon: Icons.build_circle_outlined,
                              title: strings.t('noServicesYet'),
                              message: strings.t('serviceHelp'),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final service = filtered[index];
                              return AppPanel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category.isEmpty
                          ? strings.t('uncategorized')
                          : product.category,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.stock} ${strings.t('pcs')} | ${formatCurrency(product.averageCost)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${service.customerName} | ${service.customerPhone}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<ServiceStatus>(
                                          onSelected: (status) async {
                                            await _shopService
                                                .updateServiceStatus(
                                                  service.id,
                                                  status,
                                                );
                                          },
                                          itemBuilder: (context) =>
                                              ServiceStatus.values
                                                  .map(
                                                    (status) =>
                                                        PopupMenuItem(
                                                          value: status,
                                                          child: Text(
                                                            strings
                                                                .serviceStatusLabel(
                                                                  status,
                                                                ),
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _ServiceStatusPill(
                                          label: strings.serviceStatusLabel(
                                            service.status,
                                          ),
                                          color: _statusColor(service.status),
                                        ),
                                        if (service.sparePartProductName.isNotEmpty)
                                          _ServiceStatusPill(
                                            label:
                                                '${service.sparePartProductName} x${service.sparePartQuantity}',
                                            color: const Color(0xFF6FA8FF),
                                          ),
                                        if (service.cashCost > 0)
                                          _ServiceStatusPill(
                                            label:
                                                '${strings.t('cashCost')} ${formatCurrency(service.cashCost)}',
                                            color: const Color(0xFFFF7B72),
                                          ),
                                      ],
                                    ),
                                    if (service.note.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        service.note,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    SummaryRow(
                                      label: strings.t('serviceCharge'),
                                      value: formatCurrency(
                                        service.serviceCharge,
                                      ),
                                      emphasize: true,
                                    ),
                                    SummaryRow(
                                      label: strings.t('maintenanceCost'),
                                      value: formatCurrency(service.totalCost),
                                    ),
                                    SummaryRow(
                                      label: strings.t('netProfit'),
                                      value: formatCurrency(service.netIncome),
                                      emphasize: true,
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
          );
        },
      ),
      floatingActionButton: actor == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showServiceForm(_latestProducts, actor),
              icon: const Icon(Icons.build_outlined),
              label: Text(strings.t('addServiceJob')),
            ),
    );
  }
}

class _CostModeChip extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _CostModeChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : AppTheme.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(18) : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color.withAlpha(90) : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ServicePartTile extends StatelessWidget {
  final Product product;
  final AppLocalizer strings;
  final bool selected;
  final VoidCallback onTap;

  const _ServicePartTile({
    required this.product,
    required this.strings,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Radio<bool>(
            value: true,
            groupValue: selected,
            onChanged: (_) => onTap(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category.isEmpty
                      ? strings.t('uncategorized')
                      : product.category,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.stock} ${strings.t('pcs')} | ${formatCurrency(product.averageCost)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceSummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _ServiceSummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: AppPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ServiceStatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
