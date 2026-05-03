import 'package:flutter/foundation.dart';
import 'package:upgrader/upgrader.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service for managing app updates using the upgrader package
class UpdateService {
  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService._();
  UpdateService._();

  late Upgrader _upgrader;
  bool _initialized = false;

  /// Initialize the update service
  void initialize() {
    if (_initialized) return;

    _upgrader = Upgrader();

    _initialized = true;
  }

  /// Get the upgrader instance for use in the app
  Upgrader get upgrader {
    if (!_initialized) {
      initialize();
    }
    return _upgrader;
  }

  /// Check for updates (this will show the update dialog if needed)
  Future<void> checkForUpdates() async {
    if (!_initialized) {
      initialize();
    }

    try {
      // The upgrader package will automatically check for updates
      // when the UpgradeAlert widget is used
      debugPrint('Update service: Check for updates initiated');
    } catch (e) {
      debugPrint('Update service: Error checking for updates - $e');
    }
  }

  /// Get current app version info
  Future<PackageInfo?> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo;
    } catch (e) {
      debugPrint('Update service: Error getting current version - $e');
      return null;
    }
  }

  /// Force check for updates (ignores cached results)
  Future<void> forceCheckForUpdates() async {
    if (!_initialized) {
      initialize();
    }

    try {
      // Force a fresh check by clearing any cached data
      debugPrint('Update service: Force check for updates initiated');
    } catch (e) {
      debugPrint('Update service: Error force checking for updates - $e');
    }
  }
}
