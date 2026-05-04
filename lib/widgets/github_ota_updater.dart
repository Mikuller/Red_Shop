import 'dart:io';

import 'package:flutter/material.dart';
import 'package:red_shop/services/github_ota_service.dart';

/// GitHub OTA Update Dialog
class GitHubOTAUpdateDialog extends StatefulWidget {
  final GitHubRelease release;
  final VoidCallback onCancel;

  const GitHubOTAUpdateDialog({
    super.key,
    required this.release,
    required this.onCancel,
  });

  @override
  State<GitHubOTAUpdateDialog> createState() => _GitHubOTAUpdateDialogState();
}

class _GitHubOTAUpdateDialogState extends State<GitHubOTAUpdateDialog> {
  @override
  void initState() {
    super.initState();
    // Listen to service-level progress so the dialog shows progress
    // even if it was dismissed and reopened during an active download.
    GitHubOTAService.instance.downloadProgress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    GitHubOTAService.instance.downloadProgress.removeListener(
      _onProgressChanged,
    );
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  DownloadProgress get _progress {
    return GitHubOTAService.instance.downloadProgress.value ??
        DownloadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;
    final isDownloading = p.isDownloading;
    final isInstalling = p.isInstalling;

    return AlertDialog(
      title: const Text('Update Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New version ${widget.release.version} is available!',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            widget.release.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(widget.release.body, style: const TextStyle(fontSize: 14)),
          if (isDownloading || isInstalling) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: p.total > 0 ? p.received / p.total : 0.0,
            ),
            const SizedBox(height: 8),
            Text(p.statusMessage, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Downloaded: ${(p.received / 1024 / 1024).toStringAsFixed(1)} MB / ${(p.total / 1024 / 1024).toStringAsFixed(1)} MB',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
      actions: [
        if (!isDownloading && !isInstalling) ...[
          TextButton(onPressed: widget.onCancel, child: const Text('Later')),
          ElevatedButton(
            onPressed: _downloadAndInstall,
            child: const Text('Update Now'),
          ),
        ],
        if (isDownloading && !isInstalling) ...[
          TextButton(onPressed: _cancelDownload, child: const Text('Cancel')),
        ],
        if (isInstalling)
          TextButton(onPressed: null, child: const Text('Installing...')),
      ],
    );
  }

  void _cancelDownload() {
    GitHubOTAService.instance.cancelDownload();
  }

  Future<void> _downloadAndInstall() async {
    if (widget.release.downloadUrl.isEmpty) {
      _showErrorAndPop('No APK file found in this release');
      return;
    }

    GitHubOTAService.instance.resetDownloadProgress();

    try {
      final taskId = await GitHubOTAService.instance.downloadAPK(
        widget.release.downloadUrl,
        (received, total) {
          // Progress is handled by flutter_downloader callback
        },
      );

      if (taskId == null) {
        throw Exception(
          'Failed to start download. Check debug logs for details.',
        );
      }

      // Dismiss dialog - system notification will show progress
      // Download continues in background even if app is suspended
      GitHubOTAService.instance.downloadProgress.value = DownloadProgress(
        isDownloading: true,
        statusMessage: 'Download in background - check notification',
      );
      _safePop();
    } catch (e) {
      GitHubOTAService.instance.downloadProgress.value = DownloadProgress(
        statusMessage: 'Update failed: $e',
      );
    }
  }

  void _showErrorAndPop(String message) {
    GitHubOTAService.instance.downloadProgress.value = DownloadProgress(
      statusMessage: message,
    );
    Future.delayed(const Duration(seconds: 2), _safePop);
  }

  void _safePop() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

/// GitHub OTA Update Widget - wraps the app and checks for updates
class GitHubOTAUpdater extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final GlobalKey<NavigatorState> navigatorKey;

  const GitHubOTAUpdater({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.enabled = true,
  });

  @override
  State<GitHubOTAUpdater> createState() => _GitHubOTAUpdaterState();
}

class _GitHubOTAUpdaterState extends State<GitHubOTAUpdater> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Register callback for background download completion
    GitHubOTAService.instance.onDownloadComplete = (apkFile) {
      _handleDownloadComplete(apkFile);
    };
    // Check for background downloads on app start/resume
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
    // Check immediately on start
    GitHubOTAService.instance.checkAndInstallDownload();
    if (widget.enabled) {
      _checkForUpdates();
    }
  }

  @override
  void dispose() {
    GitHubOTAService.instance.onDownloadComplete = null;
    super.dispose();
  }

  Future<void> _handleDownloadComplete(File? apkFile) async {
    if (apkFile == null) {
      debugPrint('Background download failed or was cancelled');
      return;
    }

    debugPrint('Background download complete: ${apkFile.path}');
    // Auto-install the APK even if dialog was dismissed
    final success = await GitHubOTAService.instance.installAPK(apkFile);
    if (success) {
      debugPrint('Background installation initiated');
    } else {
      debugPrint('Background installation failed');
      // Optionally show a notification here
    }
  }

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final update = await GitHubOTAService.instance.checkForUpdates();
      if (update != null && mounted) {
        // Use showDialog for proper Material dialog theming (backdrop, elevation, etc.)
        // Defer to post-frame to avoid calling showDialog during build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showUpdateDialog(update);
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _showUpdateDialog(GitHubRelease update) {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierDismissible: false, // User must choose Later or Update
      builder: (dialogContext) => GitHubOTAUpdateDialog(
        release: update,
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Lifecycle observer to check background download status when app resumes
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check if background download completed
      GitHubOTAService.instance.checkAndInstallDownload();
    }
  }
}

/// Manual update checker widget for settings
class GitHubManualUpdateChecker extends StatefulWidget {
  const GitHubManualUpdateChecker({super.key});

  @override
  State<GitHubManualUpdateChecker> createState() =>
      _GitHubManualUpdateCheckerState();
}

class _GitHubManualUpdateCheckerState extends State<GitHubManualUpdateChecker> {
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.system_update),
      title: const Text('Check for Updates'),
      subtitle: const Text('See if a new version is available on GitHub'),
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
      final update = await GitHubOTAService.instance.checkForUpdates();

      if (mounted) {
        if (update != null) {
          showDialog(
            context: context,
            builder: (context) => GitHubOTAUpdateDialog(
              release: update,
              onCancel: () => Navigator.of(context).pop(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have the latest version'),
              duration: Duration(seconds: 2),
            ),
          );
        }
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
