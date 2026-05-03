import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:red_shop/services/update_service.dart';

/// Widget that handles app updates throughout the app
/// Should be placed at the root of the widget tree
class AppUpdater extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const AppUpdater({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return UpgradeAlert(
      upgrader: UpdateService.instance.upgrader,
      child: child,
    );
  }
}

/// Widget for manual update checking (e.g., in settings)
class ManualUpdateChecker extends StatefulWidget {
  const ManualUpdateChecker({super.key});

  @override
  State<ManualUpdateChecker> createState() => _ManualUpdateCheckerState();
}

class _ManualUpdateCheckerState extends State<ManualUpdateChecker> {
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.system_update),
      title: const Text('Check for Updates'),
      subtitle: const Text('See if a new version is available'),
      trailing: _isChecking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward_ios),
      onTap: _checkForUpdates,
    );
  }

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      await UpdateService.instance.forceCheckForUpdates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update check completed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking for updates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }
}

/// Widget to display current app version
class AppVersionDisplay extends StatefulWidget {
  const AppVersionDisplay({super.key});

  @override
  State<AppVersionDisplay> createState() => _AppVersionDisplayState();
}

class _AppVersionDisplayState extends State<AppVersionDisplay> {
  String _versionInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await UpdateService.instance.getCurrentVersion();
      if (mounted && packageInfo != null) {
        setState(() {
          _versionInfo =
              'Version ${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _versionInfo = 'Version information unavailable';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_versionInfo, style: Theme.of(context).textTheme.bodySmall);
  }
}
