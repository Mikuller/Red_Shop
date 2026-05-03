import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class FastMoneyScreen extends StatefulWidget {
  const FastMoneyScreen({super.key});

  @override
  State<FastMoneyScreen> createState() => _FastMoneyScreenState();
}

class _FastMoneyScreenState extends State<FastMoneyScreen> {
  final ShopService _shopService = ShopService();

  Future<void> _showFastMoneyForm(UserModel actor) async {
    final strings = context.readStrings;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final incomeController = TextEditingController();
    final costController = TextEditingController(text: '0');
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final income = double.tryParse(incomeController.text.trim()) ?? 0;
          final cost = double.tryParse(costController.text.trim()) ?? 0;
          final profit = income - cost;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: AbsorbPointer(
              absorbing: isSaving,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.t('addFastMoney'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: strings.t('productOrService'),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? strings.t('productOrServiceRequired')
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: incomeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: strings.t('priceIncome'),
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount <= 0) {
                            return strings.t('validAmount');
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: strings.t('purchaseCost'),
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount < 0) {
                            return strings.t('validAmount');
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SummaryRow(
                              label: strings.t('priceIncome'),
                              value: formatCurrency(income),
                            ),
                            SummaryRow(
                              label: strings.t('purchaseCost'),
                              value: formatCurrency(cost),
                            ),
                            SummaryRow(
                              label: strings.t('autoProfit'),
                              value: formatCurrency(profit),
                              emphasize: true,
                            ),
                          ],
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

                                final messenger = ScaffoldMessenger.of(
                                  this.context,
                                );
                                try {
                                  setModalState(() => isSaving = true);
                                  await _shopService.recordInstantSale(
                                    itemName: nameController.text.trim(),
                                    income:
                                        double.tryParse(
                                          incomeController.text.trim(),
                                        ) ??
                                        0,
                                    cost:
                                        double.tryParse(
                                          costController.text.trim(),
                                        ) ??
                                        0,
                                    actor: actor,
                                  );
                                  if (!mounted) {
                                    return;
                                  }

                                  Navigator.of(sheetContext).pop();
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          strings.t('fastMoneySaved'),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (error) {
                                  if (!mounted) {
                                    return;
                                  }

                                  setModalState(() => isSaving = false);
                                  if (!mounted) {
                                    return;
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(describeError(error)),
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(strings.t('saveFastMoney')),
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

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final actor = context.watch<ShopAuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('fastMoney')),
        actions: const [LanguageMenuButton()],
      ),
      body: StreamBuilder<List<SaleRecord>>(
        stream: _shopService.watchInstantSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = snapshot.data ?? <SaleRecord>[];
          final totalIncome = sales.fold<double>(
            0,
            (sum, sale) => sum + sale.totalRevenue,
          );
          final totalProfit = sales.fold<double>(
            0,
            (sum, sale) => sum + sale.grossProfit,
          );
          final totalCost = sales.fold<double>(
            0,
            (sum, sale) => sum + sale.totalCost,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  children: [
                    AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.t('fastMoneyHint'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          SummaryRow(
                            label: strings.t('fastMoneyEntries'),
                            value: '${sales.length}',
                            emphasize: true,
                          ),
                          SummaryRow(
                            label: strings.t('priceIncome'),
                            value: formatCurrency(totalIncome),
                          ),
                          SummaryRow(
                            label: strings.t('purchaseCost'),
                            value: formatCurrency(totalCost),
                          ),
                          SummaryRow(
                            label: strings.t('autoProfit'),
                            value: formatCurrency(totalProfit),
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: sales.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: EmptyStateView(
                          icon: Icons.flash_on_rounded,
                          title: strings.t('noFastMoneyYet'),
                          message: strings.t('fastMoneyHelp'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                        itemCount: sales.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          return AppPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha(22),
                                      child: Icon(
                                        Icons.flash_on_rounded,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sale.primaryName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formatDateTime(sale.createdAt),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          if (sale
                                              .processedByName
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              strings.t('addedBy', {
                                                'name': sale.processedByName,
                                              }),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SummaryRow(
                                  label: strings.t('priceIncome'),
                                  value: formatCurrency(sale.totalRevenue),
                                ),
                                SummaryRow(
                                  label: strings.t('purchaseCost'),
                                  value: formatCurrency(sale.totalCost),
                                ),
                                SummaryRow(
                                  label: strings.t('autoProfit'),
                                  value: formatCurrency(sale.grossProfit),
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
      ),
      floatingActionButton: actor == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showFastMoneyForm(actor),
              icon: const Icon(Icons.flash_on_rounded),
              label: Text(strings.t('fastMoney')),
            ),
    );
  }
}
