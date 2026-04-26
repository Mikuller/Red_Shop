import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                    'Add expense',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<ExpenseKind>(
                    initialValue: kind,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ExpenseKind.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(expenseKindLabel(value)),
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
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Description is required.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount.';
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
                        : const Text('Save expense'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense'),
        content: Text('Delete "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
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
                          label: 'Operating',
                          value: formatCurrency(operating),
                          emphasize: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPanel(
                        child: SummaryRow(
                          label: 'Withdrawals',
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
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: EmptyStateView(
                          icon: Icons.receipt_long_outlined,
                          title: 'No expenses yet',
                          message:
                              'Track operating costs and owner withdrawals here.',
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
                                          'Added by ${expense.createdByName}',
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
                                        expenseKindLabel(expense.kind),
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
        label: const Text('Expense'),
      ),
    );
  }
}
