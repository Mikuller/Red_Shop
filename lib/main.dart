import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/firebase_options.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/screens/auth/login_screen.dart';
import 'package:red_shop/screens/clerk/clerk_home.dart';
import 'package:red_shop/screens/owner/owner_home.dart';
import 'package:red_shop/services/auth_service.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RedShopApp());
}

class RedShopApp extends StatelessWidget {
  const RedShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShopAuthProvider(),
      child: MaterialApp(
        title: 'Red Computer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _BlockingScreen(
            title: 'Preparing your workspace',
            message: 'Connecting to Firebase and loading your profile.',
          );
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ShopAuthProvider>().setUser(null);
          });
          return const LoginScreen();
        }

        return FutureBuilder<UserModel?>(
          future: AuthService().getUserProfile(firebaseUser.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _BlockingScreen(
                title: 'Loading your workspace',
                message: 'Checking your role and shop access.',
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return _ActionRequiredScreen(
                title: 'Profile missing',
                message:
                    'Your Firebase account exists, but the shop profile record is missing.',
                actionLabel: 'Sign out',
                onAction: () async {
                  await context.read<ShopAuthProvider>().logout();
                },
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<ShopAuthProvider>().setUser(profile);
            });

            if (!profile.active) {
              return _ActionRequiredScreen(
                title: 'Access disabled',
                message:
                    'This account has been disabled by the owner. Please contact the shop owner if that looks wrong.',
                actionLabel: 'Sign out',
                onAction: () async {
                  await context.read<ShopAuthProvider>().logout();
                },
              );
            }

            if (profile.role == UserRole.owner) {
              return const OwnerHome();
            }

            return const ClerkHome();
          },
        );
      },
    );
  }
}

class _BlockingScreen extends StatelessWidget {
  final String title;
  final String message;

  const _BlockingScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRequiredScreen extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _ActionRequiredScreen({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyStateView(
              icon: Icons.lock_outline,
              title: title,
              message: message,
              actionLabel: actionLabel,
              onAction: onAction,
            ),
          ),
        ),
      ),
    );
  }
}
