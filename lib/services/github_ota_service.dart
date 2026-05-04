import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

/// GitHub Release information model
class GitHubRelease {
  final String tagName;
  final String name;
  final String body;
  final String downloadUrl;
  final DateTime publishedAt;

  GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.downloadUrl,
    required this.publishedAt,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    // Find the APK file in assets
    String downloadUrl = '';
    if (json['assets'] != null) {
      for (var asset in json['assets']) {
        if (asset['name'].toString().endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] ?? '';
          break;
        }
      }
    }

    // Parse published_at safely
    DateTime publishedAt;
    try {
      publishedAt = DateTime.parse(json['published_at'] ?? '');
    } catch (e) {
      debugPrint(
        'Error parsing published_at: ${json['published_at']}, using current time',
      );
      publishedAt = DateTime.now();
    }

    return GitHubRelease(
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      downloadUrl: downloadUrl,
      publishedAt: publishedAt,
    );
  }

  /// Extract version number from tag (removes 'v' prefix if present)
  String get version {
    return tagName.startsWith('v') ? tagName.substring(1) : tagName;
  }
}

/// Download progress data
class DownloadProgress {
  final int received;
  final int total;
  final bool isDownloading;
  final bool isInstalling;
  final String statusMessage;

  DownloadProgress({
    this.received = 0,
    this.total = 0,
    this.isDownloading = false,
    this.isInstalling = false,
    this.statusMessage = '',
  });
}

/// GitHub-based OTA update service
class GitHubOTAService {
  static GitHubOTAService? _instance;
  static GitHubOTAService get instance => _instance ??= GitHubOTAService._();
  GitHubOTAService._();

  // Background download cancellation
  bool _isDownloadCancelled = false;
  void cancelDownload() {
    _isDownloadCancelled = true;
  }

  /// Service-level download progress notifier.
  /// Survives dialog dismissal so background downloads report progress
  /// even when the update dialog is not visible.
  final ValueNotifier<DownloadProgress?> downloadProgress =
      ValueNotifier<DownloadProgress?>(null);

  /// Callback triggered when download completes (even if dialog was dismissed).
  /// Passes the downloaded APK file if successful, null if cancelled/failed.
  void Function(File?)? onDownloadComplete;

  /// Current download task ID
  String? _currentTaskId;

  /// Last download URL for retry
  String? _lastDownloadUrl;

  /// Last release info for retry dialog
  GitHubRelease? _lastRelease;

  /// Whether the last download failed
  bool _downloadFailed = false;

  /// Get whether download failed (for retry UI)
  bool get downloadFailed => _downloadFailed;

  /// Get last download URL (for retry)
  String? get lastDownloadUrl => _lastDownloadUrl;

  /// Get last release info (for retry dialog)
  GitHubRelease? get lastRelease => _lastRelease;

  /// Reset download progress state
  void resetDownloadProgress() {
    downloadProgress.value = null;
    _currentTaskId = null;
    _lastDownloadUrl = null;
    _lastRelease = null;
    _downloadFailed = false;
  }

  // TODO: Replace with your actual GitHub repository details
  static const String _githubOwner =
      'Mikuller'; // Replace with your GitHub username
  static const String _githubRepo =
      'Red_Shop'; // Replace with your repository name

  // Temporary flag to disable update checking until repository is set up
  static const bool _enableUpdateChecking = true;

  /// Check for updates from GitHub Releases
  Future<GitHubRelease?> checkForUpdates() async {
    // Temporarily enable debug mode for testing
    // if (kDebugMode) {
    //   debugPrint('Update checking disabled in debug mode');
    //   return null;
    // }

    // Temporarily disable update checking until repository is set up
    if (!_enableUpdateChecking) {
      debugPrint('Update checking is disabled');
      return null;
    }

    try {
      debugPrint('Getting package info...');
      final currentPackage = await PackageInfo.fromPlatform();
      final currentVersion = currentPackage.version;

      debugPrint('Current app version: $currentVersion');
      debugPrint('Package name: ${currentPackage.packageName}');
      debugPrint('Build number: ${currentPackage.buildNumber}');

      final url = Uri.parse(
        'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest',
      );

      debugPrint('Checking for updates from: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'Red-Shop-App',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('GitHub API request timed out');
              throw Exception('Request timeout');
            },
          );

      debugPrint('GitHub API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          debugPrint('Parsing GitHub response JSON...');
          final jsonData = jsonDecode(response.body);
          debugPrint('JSON parsed successfully, creating GitHubRelease...');

          final release = GitHubRelease.fromJson(jsonData);

          debugPrint(
            'GitHub release found: ${release.tagName} -> ${release.version}',
          );
          debugPrint('Download URL: ${release.downloadUrl}');

          // Check if download URL is found
          if (release.downloadUrl.isEmpty) {
            debugPrint('No APK file found in release ${release.tagName}');
            return null;
          }

          // Compare versions (simple string comparison, you might want to use package_info_plus)
          final isNewer = _isNewerVersion(release.version, currentVersion);
          debugPrint(
            'Is ${release.version} newer than $currentVersion? $isNewer',
          );

          if (isNewer) {
            debugPrint(
              'New version available: ${release.version} (current: $currentVersion)',
            );
            return release;
          } else {
            debugPrint('Current version $currentVersion is up to date');
          }
        } catch (e) {
          debugPrint('Error parsing GitHub release data: $e');
          debugPrint('Response body: ${response.body}');
          return null;
        }
      } else if (response.statusCode == 404) {
        debugPrint(
          'Repository $_githubOwner/$_githubRepo not found or has no releases',
        );
      } else {
        debugPrint(
          'GitHub API error: ${response.statusCode} - ${response.body}',
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  /// Download APK using flutter_downloader for true background support
  /// Returns the download task ID. Download continues even if app is suspended.
  Future<String?> downloadAPK(
    String downloadUrl,
    Function(int, int) onProgress, {
    GitHubRelease? release,
  }) async {
    try {
      debugPrint('Starting background APK download from: $downloadUrl');
      _isDownloadCancelled = false;
      _lastDownloadUrl = downloadUrl;
      _lastRelease = release;
      _downloadFailed = false;

      // Request notification permission for Android 13+
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isDenied) {
          debugPrint('Requesting notification permission');
          await Permission.notification.request();
        }
      }

      // Download to app cache directory
      final tempDir = await getTemporaryDirectory();
      final savedDir = tempDir.path;

      // Initialize progress notifier
      downloadProgress.value = DownloadProgress(
        received: 0,
        total: 0,
        isDownloading: true,
        statusMessage: 'Download started in background',
      );

      // Use flutter_downloader with system notification (simplest approach)
      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: savedDir,
        fileName: 'red_shop_update.apk',
        showNotification: true, // Show system notification
        openFileFromNotification: false, // We'll handle install manually
      );

      _currentTaskId = taskId;
      debugPrint('Background download started with task ID: $taskId');
      return taskId;
    } catch (e) {
      debugPrint('Error starting background download: $e');
      onDownloadComplete?.call(null);
      return null;
    }
  }

  /// Retry the last failed download
  Future<String?> retryDownload(Function(int, int) onProgress) async {
    if (_lastDownloadUrl == null) {
      debugPrint('No previous download URL to retry');
      return null;
    }
    debugPrint('Retrying download: $_lastDownloadUrl');
    _downloadFailed = false;
    return downloadAPK(_lastDownloadUrl!, onProgress, release: _lastRelease);
  }

  /// Check download status and auto-install if complete
  Future<void> checkAndInstallDownload() async {
    if (_currentTaskId == null) return;

    try {
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: 'SELECT * FROM task WHERE task_id = "$_currentTaskId"',
      );

      if (tasks != null && tasks.isNotEmpty) {
        final task = tasks.first;
        if (task.status == DownloadTaskStatus.complete) {
          debugPrint('Download complete: ${task.savedDir}/${task.filename}');
          final apkFile = File('${task.savedDir}/${task.filename}');
          if (await apkFile.exists()) {
            debugPrint('Installing APK from background download');
            await installAPK(apkFile);
            _currentTaskId = null;
          }
        } else if (task.status == DownloadTaskStatus.failed ||
            task.status == DownloadTaskStatus.canceled) {
          debugPrint('Background download failed or cancelled');
          _downloadFailed = true;
          downloadProgress.value = DownloadProgress(
            statusMessage: 'Download failed - tap Retry',
          );
          _currentTaskId = null;
        }
      }
    } catch (e) {
      debugPrint('Error checking download status: $e');
    }
  }

  /// Install the downloaded APK
  Future<bool> installAPK(File apkFile) async {
    try {
      if (Platform.isAndroid) {
        // Verify file exists before attempting installation
        if (!await apkFile.exists()) {
          debugPrint('APK file does not exist: ${apkFile.path}');
          return false;
        }

        final fileSize = await apkFile.length();
        debugPrint('Installing APK: ${apkFile.path} (${fileSize} bytes)');

        if (fileSize == 0) {
          debugPrint('Error: APK file is empty');
          return false;
        }

        // Verify APK is valid by checking the ZIP signature (APK is a ZIP file)
        final headerBytes = await apkFile.openRead(0, 4).first;
        if (headerBytes.length < 4 ||
            headerBytes[0] != 0x50 || // 'P'
            headerBytes[1] != 0x4B || // 'K'
            headerBytes[2] != 0x03 || // 0x03
            headerBytes[3] !=
                0x04 // 0x04
                ) {
          debugPrint(
            'Error: Downloaded file is not a valid APK (invalid ZIP header)',
          );
          debugPrint(
            'Header bytes: ${headerBytes.map((b) => '0x${b.toRadixString(16)}').join(', ')}',
          );
          return false;
        }
        debugPrint('APK ZIP header verified');

        // Use FileProvider content URI for secure file access
        // cache-path maps to getCacheDir() which matches getTemporaryDirectory()
        final packageName = 'com.example.red_shop';
        final contentUri =
            'content://$packageName.fileprovider/cache/red_shop_update.apk';

        debugPrint('Launching installer with URI: $contentUri');

        final intent = AndroidIntent(
          action: 'android.intent.action.INSTALL_PACKAGE',
          data: contentUri,
          type: 'application/vnd.android.package-archive',
          flags: <int>[
            Flag.FLAG_ACTIVITY_NEW_TASK,
            Flag.FLAG_GRANT_READ_URI_PERMISSION,
          ],
        );

        await intent.launch();
        debugPrint('APK installation initiated successfully');
        return true;
      } else {
        debugPrint('APK installation only supported on Android');
        return false;
      }
    } catch (e) {
      debugPrint('Error installing APK: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Simple version comparison (you might want to use a more sophisticated method)
  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latestParts = latestVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      // Pad with zeros if needed
      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) {
          return true;
        } else if (latestParts[i] < currentParts[i]) {
          return false;
        }
      }
      return false; // Versions are equal
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  /// Get current app version
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('Error getting current version: $e');
      return '0.0.0';
    }
  }

  /// Get current app build number
  Future<String> getCurrentBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      debugPrint('Error getting current build number: $e');
      return '0';
    }
  }
}
