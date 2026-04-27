import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ShopService _shopService = ShopService();

  Future<void> _showExpenseForm() async {
    final strings = context.readStrings;
    final actor = context.read<ShopAuthProvider>().userModel;
    if (actor == null) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    var kind = ExpenseKind.operating;
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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.t('addExpense'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<ExpenseKind>(
                    initialValue: kind,
                    decoration: InputDecoration(labelText: strings.t('type')),
                    items: ExpenseKind.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(strings.expenseKindLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => kind = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: strings.t('description'),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? strings.t('descriptionRequired')
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
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: strings.t('amount')),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return strings.t('validAmount');
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final navigator = Navigator.of(sheetContext);
                            final messenger = ScaffoldMessenger.of(
                              this.context,
                            );
                            try {
                              setModalState(() => isSaving = true);
                              await _shopService.addExpense(
                                description: descriptionController.text.trim(),
                                category: categoryController.text.trim(),
                                amount:
                                    double.tryParse(
                                      amountController.text.trim(),
                                    ) ??
                                    0,
                                kind: kind,
                                actor: actor,
                              );
                              if (!mounted) {
                                return;
                              }

                              navigator.pop();
                            } catch (error) {
                              if (!mounted) {
                                return;
                              }

                              setModalState(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text(describeError(error))),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(strings.t('saveExpense')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteExpense(ExpenseRecord expense) async {
    final strings = context.readStrings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('deleteExpense')),
        content: Text(
          strings.t('deleteExpenseMessage', {'name': expense.description}),
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

    await _shopService.deleteExpense(expense.id);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('expenses')),
        actions: const [LanguageMenuButton()],
      ),
      body: StreamBuilder<List<ExpenseRecord>>(
        stream: _shopService.watchExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data ?? <ExpenseRecord>[];
          final operating = expenses
              .where((expense) => expense.kind == ExpenseKind.operating)
              .fold<double>(0, (sum, expense) => sum + expense.amount);
          final withdrawals = expenses
              .where((expense) => expense.kind == ExpenseKind.withdrawal)
              .fold<double>(0, (sum, expense) => sum + expense.amount);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: AppPanel(
                        child: SummaryRow(
                          label: strings.t('operating'),
                          value: formatCurrency(operating),
                          emphasize: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPanel(
                        child: SummaryRow(
                          label: strings.t('withdrawals'),
                          value: formatCurrency(withdrawals),
                          emphasize: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: expenses.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(20),
                        child: EmptyStateView(
                          icon: Icons.receipt_long_outlined,
                          title: strings.t('noExpenseItemsYet'),
                          message: strings.t('expenseHelp'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: expenses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return AppPanel(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      expense.kind == ExpenseKind.operating
                                      ? Colors.orange.withAlpha(28)
                                      : Colors.red.withAlpha(28),
                                  child: Icon(
                                    expense.kind == ExpenseKind.operating
                                        ? Icons.receipt_long_outlined
                                        : Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${expense.category} | ${formatDateTime(expense.createdAt)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      if (expense.createdByName.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          strings.t('addedBy', {
                                            'name': expense.createdByName,
                                          }),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatCurrency(expense.amount),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Chip(
                                      label: Text(
                                        strings.expenseKindLabel(expense.kind),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteExpense(expense),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
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
        onPressed: _showExpenseForm,
        icon: const Icon(Icons.add),
        label: Text(strings.t('expenseFab')),
      ),
    );
  }
}
