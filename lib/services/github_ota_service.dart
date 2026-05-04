import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

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
            const Duration(seconds: 10),
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

  /// Download APK from GitHub release with optimized performance
  Future<File?> downloadAPK(
    String downloadUrl,
    Function(int, int) onProgress,
  ) async {
    try {
      debugPrint('Starting APK download from: $downloadUrl');
      _isDownloadCancelled = false;

      // Use a more efficient HTTP client with larger buffer
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));

      // Add headers for better performance
      request.headers.addAll({
        'Accept-Encoding': 'gzip',
        'User-Agent': 'Red-Shop-App',
        'Connection': 'keep-alive',
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        debugPrint('Failed to download APK: ${streamedResponse.statusCode}');
        client.close();
        return null;
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      debugPrint(
        'APK file size: ${(contentLength / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Download to app cache directory for reliable FileProvider access
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/red_shop_update.apk');

      // Check if file already exists and delete it
      if (await apkFile.exists()) {
        await apkFile.delete();
        debugPrint('Deleted existing APK file');
      }

      // Open file for writing with buffering
      final sink = apkFile.openWrite();
      int received = 0;
      final startTime = DateTime.now();

      try {
        // Download with larger chunks for better performance
        await for (final chunk in streamedResponse.stream) {
          // Check for cancellation
          if (_isDownloadCancelled) {
            debugPrint('Download cancelled by user');
            try {
              await sink.close();
            } catch (e) {
              debugPrint('Error closing sink: $e');
            }
            try {
              client.close();
            } catch (e) {
              debugPrint('Error closing client: $e');
            }
            if (await apkFile.exists()) {
              await apkFile.delete();
            }
            return null;
          }

          sink.add(chunk);
          received += chunk.length;
          onProgress(received, contentLength);

          // Debug progress less frequently to reduce overhead
          if (contentLength > 0 && received % (1024 * 1024) == 0) {
            // Every 1MB
            final elapsed = DateTime.now().difference(startTime).inMilliseconds;
            final speed = elapsed > 0
                ? (received / 1024 / 1024) / (elapsed / 1000)
                : 0;
            debugPrint(
              'Downloaded: ${(received / 1024 / 1024).toStringAsFixed(2)} MB, Speed: ${speed.toStringAsFixed(2)} MB/s',
            );
          }
        }
      } finally {
        await sink.close();
        client.close();
      }

      // Verify file was written correctly
      final fileSize = await apkFile.length();
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      final avgSpeed = totalTime > 0
          ? (fileSize / 1024 / 1024) / (totalTime / 1000)
          : 0;

      debugPrint('APK downloaded to: ${apkFile.path}');
      debugPrint(
        'Downloaded file size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      debugPrint(
        'Total time: ${totalTime / 1000}s, Average speed: ${avgSpeed.toStringAsFixed(2)} MB/s',
      );

      if (fileSize == 0) {
        debugPrint('Error: Downloaded file is empty');
        return null;
      }

      return apkFile;
    } catch (e) {
      debugPrint('Error downloading APK: $e');
      return null;
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
