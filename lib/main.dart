import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/firebase_options.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/providers/auth_provider.dart';
import 'package:red_shop/screens/auth/login_screen.dart';
import 'package:red_shop/screens/clerk/clerk_home.dart';
import 'package:red_shop/screens/dev/cheatsheet_preview.dart';
import 'package:red_shop/screens/owner/owner_home.dart';
import 'package:red_shop/services/auth_service.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/widgets/shop_widgets.dart';
import 'package:red_shop/widgets/github_ota_updater.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  // Callback runs in isolate - just log for debugging
  // Status: 0=undefined, 1=enqueued, 2=running, 3=complete, 4=failed, 5=paused, 6=canceled
  debugPrint('Download: $id, status: $status, progress: $progress');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FlutterDownloader.initialize(debug: kDebugMode);
  FlutterDownloader.registerCallback(downloadCallback);

  runApp(RedShopApp());
}

class RedShopApp extends StatelessWidget {
  RedShopApp({super.key});

  /// Navigator key used by the OTA updater to show dialogs reliably.
  /// MaterialApp places its Navigator *after* the builder, so the builder's
  /// context does not have a Navigator ancestor. Using a GlobalKey lets us
  /// show dialogs from code that runs outside the normal widget tree flow.
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final previewMode = cheatsheetPreviewModeFromUri(Uri.base);
    final initialLanguage = _languageFromUri(Uri.base);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShopAuthProvider()),
        ChangeNotifierProvider(
          create: (_) => AppLanguageProvider(initialLanguage: initialLanguage),
        ),
      ],
      child: Consumer<AppLanguageProvider>(
        builder: (context, language, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: language.strings.t('appName'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(),
            builder: (context, child) {
              return GitHubOTAUpdater(
                navigatorKey: _navigatorKey,
                child: child!,
              );
            },
            home: !kReleaseMode && previewMode != null
                ? CheatsheetPreviewScreen(mode: previewMode)
                : const AuthWrapper(),
          );
        },
      ),
    );
  }
}

AppLanguage _languageFromUri(Uri uri) {
  return uri.queryParameters['lang'] == 'am'
      ? AppLanguage.amharic
      : AppLanguage.english;
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          final strings = context.strings;
          return _BlockingScreen(
            title: strings.t('preparingWorkspace'),
            message: strings.t('connectingFirebase'),
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
              final strings = context.strings;
              return _BlockingScreen(
                title: strings.t('loadingWorkspace'),
                message: strings.t('checkingAccess'),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              final strings = context.strings;
              return _ActionRequiredScreen(
                title: strings.t('profileMissingTitle'),
                message: strings.t('profileMissingMessage'),
                actionLabel: strings.t('signOut'),
                onAction: () async {
                  await context.read<ShopAuthProvider>().logout();
                },
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<ShopAuthProvider>().setUser(profile);
            });

            if (!profile.active) {
              final strings = context.strings;
              return _ActionRequiredScreen(
                title: strings.t('accessDisabledTitle'),
                message: strings.t('accessDisabledMessage'),
                actionLabel: strings.t('signOut'),
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
