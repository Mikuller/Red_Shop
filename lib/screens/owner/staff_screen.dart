import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/services/auth_service.dart';
import 'package:red_shop/services/shop_service.dart';
import 'package:red_shop/widgets/shop_widgets.dart';
import 'package:red_shop/utils/formatters.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final ShopService _shopService = ShopService();

  Future<void> _showAddStaffDialog() async {
    final strings = context.readStrings;
    final actor = context.read<ShopAuthProvider>().userModel;
    if (actor == null) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var role = UserRole.clerk;
    var obscurePassword = true;
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
                    strings.t('createStaffAccount'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<UserRole>(
                    initialValue: role,
                    decoration: InputDecoration(labelText: strings.t('role')),
                    items: UserRole.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(strings.roleLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => role = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: strings.t('fullName'),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? strings.t('nameRequired')
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: strings.t('email')),
                    validator: (value) => value == null || !value.contains('@')
                        ? strings.t('needValidEmail')
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: strings.t('temporaryPassword'),
                      suffixIcon: IconButton(
                        onPressed: () => setModalState(
                          () => obscurePassword = !obscurePassword,
                        ),
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? strings.t('minPassword')
                        : null,
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
                              await AuthService().createStaffAccount(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                                name: nameController.text.trim(),
                                role: role,
                                actor: actor,
                              );
                              if (!mounted) {
                                return;
                              }

                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(strings.t('staffCreated')),
                                ),
                              );
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
                        : Text(strings.t('createAccount')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleUser(UserModel user) async {
    await _shopService.toggleUserActive(user);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<ShopAuthProvider>().userModel;
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('staff')),
        actions: const [LanguageMenuButton()],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _shopService.watchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? <UserModel>[];
          final activeUsers = users.where((user) => user.active).length;
          final ownerCount = users
              .where((user) => user.role == UserRole.owner)
              .length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppPanel(
                            child: SummaryRow(
                              label: strings.t('activeUsers'),
                              value: '$activeUsers',
                              emphasize: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppPanel(
                            child: SummaryRow(
                              label: strings.t('owners'),
                              value: '$ownerCount',
                              emphasize: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppPanel(child: Text(strings.t('staffNote'))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: users.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(20),
                        child: EmptyStateView(
                          icon: Icons.group_outlined,
                          title: strings.t('noStaffYet'),
                          message: strings.t('staffHelp'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isCurrentUser = user.uid == currentUser?.uid;
                          return AppPanel(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  child: Text(
                                    user.name.isEmpty
                                        ? '?'
                                        : user.name[0].toUpperCase(),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          Chip(
                                            label: Text(
                                              strings.roleLabel(user.role),
                                            ),
                                          ),
                                          Chip(
                                            label: Text(
                                              user.active
                                                  ? strings.t('active')
                                                  : strings.t('disabled'),
                                            ),
                                          ),
                                          if (isCurrentUser)
                                            Chip(label: Text(strings.t('you'))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Switch.adaptive(
                                      value: user.active,
                                      onChanged: isCurrentUser
                                          ? null
                                          : (_) => _toggleUser(user),
                                    ),
                                    Text(
                                      formatDate(user.createdAt),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
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
        onPressed: _showAddStaffDialog,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(strings.t('staffFab')),
      ),
    );
  }
}
