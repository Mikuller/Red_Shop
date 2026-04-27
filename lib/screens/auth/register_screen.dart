import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/services/auth_service.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _handleRegister() async {
    final strings = context.readStrings;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await context.read<ShopAuthProvider>().registerInitialOwner(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.t('ownerCreated'))));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(describeError(error))));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<ShopAuthProvider>();
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('ownerSetup')),
        actions: const [LanguageMenuButton()],
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: AuthService().ownerRegistrationAvailable(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final canRegister = snapshot.data ?? false;
            if (!canRegister) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyStateView(
                    icon: Icons.verified_user_outlined,
                    title: strings.t('ownerAlreadyConfiguredTitle'),
                    message: strings.t('ownerAlreadyConfiguredMessage'),
                  ),
                ),
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: AppPanel(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.t('firstOwnerTitle'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            strings.t('firstOwnerMessage'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: strings.t('fullName'),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? strings.t('enterName')
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: strings.t('email'),
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: (value) =>
                                value == null || !value.contains('@')
                                ? strings.t('needValidEmail')
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: strings.t('password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.length < 6
                                ? strings.t('minPassword')
                                : null,
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton(
                            onPressed: authProvider.isBusy
                                ? null
                                : _handleRegister,
                            child: authProvider.isBusy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(strings.t('createOwnerAccount')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
