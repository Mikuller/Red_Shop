import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/screens/pos/pos_screen.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class ClerkHome extends StatelessWidget {
  const ClerkHome({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('salesPos')),
        actions: [
          const LanguageMenuButton(),
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
