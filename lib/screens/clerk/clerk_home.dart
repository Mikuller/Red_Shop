import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/screens/owner/expense_screen.dart';
import 'package:red_shop/screens/owner/service_screen.dart';
import 'package:red_shop/screens/pos/pos_screen.dart';
import 'package:red_shop/screens/shared/fast_money_screen.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class ClerkHome extends StatelessWidget {
  const ClerkHome({super.key});

  Future<void> _openScreen(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _showToolsSheet(BuildContext context) async {
    final strings = context.readStrings;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceAlt,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.t('moreActions'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _ClerkActionTile(
                  icon: Icons.flash_on_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  title: strings.t('fastMoney'),
                  subtitle: strings.t('fastMoneyHint'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openScreen(context, const FastMoneyScreen());
                  },
                ),
                const SizedBox(height: 12),
                _ClerkActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFFFF7B72),
                  title: strings.t('expenses'),
                  subtitle: strings.t('trackSpendAndWithdrawals'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openScreen(context, const ExpenseScreen());
                  },
                ),
                const SizedBox(height: 12),
                _ClerkActionTile(
                  icon: Icons.build_circle_outlined,
                  color: const Color(0xFF6FA8FF),
                  title: strings.t('services'),
                  subtitle: strings.t('serviceShortHint'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openScreen(context, const ServiceScreen());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('salesPos')),
        actions: [
          const LanguageMenuButton(),
          IconButton(
            tooltip: strings.t('moreActions'),
            onPressed: () => _showToolsSheet(context),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
          IconButton(
            tooltip: strings.t('logout'),
            onPressed: () => context.read<ShopAuthProvider>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: PosScreen(title: strings.t('salesPos'), showAppBar: false),
    );
  }
}

class _ClerkActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ClerkActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}
