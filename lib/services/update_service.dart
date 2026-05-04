import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';

/// Service for managing app updates and installation
class UpdateService {
  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService._();
  UpdateService._();

  late Upgrader _upgrader;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;

    _upgrader = Upgrader();

    _initialized = true;
  }

  Upgrader get upgrader {
    if (!_initialized) {
      initialize();
    }
    return _upgrader;
  }

  Future<void> checkForUpdates() async {
    if (!_initialized) {
      initialize();
    }
    try {
      debugPrint('Update service: Check for updates initiated');
    } catch (e) {
      debugPrint('Update service: Error checking for updates - $e');
    }
  }

  Future<PackageInfo?> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo;
    } catch (e) {
      debugPrint('Update service: Error getting current version - $e');
      return null;
    }
  }

  Future<void> forceCheckForUpdates() async {
    if (!_initialized) {
      initialize();
    }
    try {
      debugPrint('Update service: Force check for updates initiated');
    } catch (e) {
      debugPrint('Update service: Error force checking for updates - $e');
    }
  }

  /// Installs an APK file from a given path
  Future<void> installApk(String filePath) async {
    if (!Platform.isAndroid) return;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('APK file not found at path: $filePath');
      }

      final intent = AndroidIntent(
        action: 'action_view',
        data: 'file://$filePath',
        type: 'application/vnd.android.package-archive',
      );

      await intent.launch();
    } catch (e) {
      debugPrint('Update service: Installation failed - $e');
      rethrow;
    }
  }
}
