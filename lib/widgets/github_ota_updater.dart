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
  bool _isDownloading = false;
  bool _isInstalling = false;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AlertDialog(
          title: const Text('Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New version ${widget.release.version} is available!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.release.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.release.body,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (_isDownloading || _isInstalling) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _totalBytes > 0 ? _downloadedBytes / _totalBytes : 0.0,
                ),
                const SizedBox(height: 8),
                Text(_statusMessage, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  'Downloaded: ${(_downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB / ${(_totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            if (!_isDownloading && !_isInstalling) ...[
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: _downloadAndInstall,
                child: const Text('Update Now'),
              ),
            ],
            if (_isDownloading && !_isInstalling) ...[
              TextButton(
                onPressed: _cancelDownload,
                child: const Text('Cancel'),
              ),
            ],
            if (_isInstalling)
              TextButton(onPressed: null, child: const Text('Installing...')),
          ],
        ),
      ),
    );
  }

  void _cancelDownload() {
    GitHubOTAService.instance.cancelDownload();
    setState(() {
      _isDownloading = false;
      _statusMessage = 'Download cancelled';
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _downloadAndInstall() async {
    if (widget.release.downloadUrl.isEmpty) {
      setState(() {
        _statusMessage = 'No APK file found in this release';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadedBytes = 0;
      _totalBytes = 0;
      _statusMessage = 'Downloading update...';
    });

    try {
      // Download the APK
      final apkFile = await GitHubOTAService.instance.downloadAPK(
        widget.release.downloadUrl,
        (received, total) {
          setState(() {
            _downloadedBytes = received;
            _totalBytes = total;
            if (total > 0) {
              final progress = (received / total * 100).toStringAsFixed(1);
              _statusMessage = 'Downloading: $progress%';
            } else {
              _statusMessage = 'Downloading...';
            }
          });
        },
      );

      if (apkFile == null) {
        throw Exception(
          'Failed to download APK. Check debug logs for details.',
        );
      }

      setState(() {
        _isDownloading = false;
        _isInstalling = true;
        _statusMessage = 'Installing update...';
      });

      // Install the APK
      final success = await GitHubOTAService.instance.installAPK(apkFile);

      if (success) {
        setState(() {
          _statusMessage = 'Update installed successfully!';
        });

        // Close dialog after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        throw Exception('Failed to install APK');
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _isInstalling = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// GitHub OTA Update Widget - wraps the app and checks for updates
class GitHubOTAUpdater extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const GitHubOTAUpdater({super.key, required this.child, this.enabled = true});

  @override
  State<GitHubOTAUpdater> createState() => _GitHubOTAUpdaterState();
}

class _GitHubOTAUpdaterState extends State<GitHubOTAUpdater> {
  GitHubRelease? _pendingUpdate;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final update = await GitHubOTAService.instance.checkForUpdates();
      if (update != null) {
        setState(() {
          _pendingUpdate = update;
        });
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    if (_pendingUpdate != null) {
      content = Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            content,
            if (_pendingUpdate != null)
              GitHubOTAUpdateDialog(
                release: _pendingUpdate!,
                onCancel: () {
                  setState(() {
                    _pendingUpdate = null;
                  });
                },
              ),
          ],
        ),
      );
    }

    return content;
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
