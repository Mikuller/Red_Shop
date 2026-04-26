import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/screens/pos/pos_screen.dart';

class ClerkHome extends StatelessWidget {
  const ClerkHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales POS'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => context.read<ShopAuthProvider>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const PosScreen(title: 'Sales POS', showAppBar: false),
    );
  }
}
