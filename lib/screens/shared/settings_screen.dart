import 'package:flutter/material.dart';
import 'package:red_shop/widgets/github_ota_updater.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SectionHeader(title: 'App Information'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('Red Shop - Point of Sale System'),
          ),
          const Divider(),

          const SectionHeader(title: 'Updates'),
          const GitHubManualUpdateChecker(),
          const Divider(),

          const SectionHeader(title: 'Preferences'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('App language settings'),
            onTap: () {
              // TODO: Navigate to language settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('App theme settings'),
            onTap: () {
              // TODO: Navigate to theme settings
            },
          ),
          const Divider(),

          const SectionHeader(title: 'Support'),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help with the app'),
            onTap: () {
              // TODO: Navigate to help screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            subtitle: const Text('Share your feedback with us'),
            onTap: () {
              // TODO: Open feedback form
            },
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
