import 'package:flutter/services.dart';

/// Bridges to the native Android AppMonitorService and overlay system.
/// Uses MethodChannel to communicate with Kotlin.
class ScreenTimeService {
  static const _channel = MethodChannel('com.tezjmc.learnlock/app_control');

  /// Request PACKAGE_USAGE_STATS permission (opens system settings)
  static Future<bool> hasUsageStatsPermission() async {
    final granted = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
    return granted ?? false;
  }

  static Future<void> requestUsageStatsPermission() =>
      _channel.invokeMethod('requestUsageStatsPermission');

  /// Request SYSTEM_ALERT_WINDOW (overlay) permission
  static Future<bool> hasOverlayPermission() async {
    final granted = await _channel.invokeMethod<bool>('hasOverlayPermission');
    return granted ?? false;
  }

  static Future<void> requestOverlayPermission() =>
      _channel.invokeMethod('requestOverlayPermission');

  /// Start the background app monitor service
  static Future<void> startMonitor({
    required String childId,
    required bool hasScreenTime,
    required DateTime? expiresAt,
  }) =>
      _channel.invokeMethod('startMonitor', {
        'childId': childId,
        'hasScreenTime': hasScreenTime,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
      });

  /// Stop the background monitor
  static Future<void> stopMonitor() => _channel.invokeMethod('stopMonitor');

  /// Update screen time status without restarting the service
  static Future<void> updateScreenTime({
    required bool hasScreenTime,
    required DateTime? expiresAt,
  }) =>
      _channel.invokeMethod('updateScreenTime', {
        'hasScreenTime': hasScreenTime,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
      });

  /// Get total foreground time in seconds for the current day
  static Future<int> getTodayUsageSeconds() async {
    final secs = await _channel.invokeMethod<int>('getTodayUsageSeconds');
    return secs ?? 0;
  }

  /// Check whether the LearnLock accessibility service is enabled
  static Future<bool> hasAccessibilityPermission() async {
    final granted = await _channel.invokeMethod<bool>('hasAccessibilityPermission');
    return granted ?? false;
  }

  static Future<void> requestAccessibilityPermission() =>
      _channel.invokeMethod('requestAccessibilityPermission');

  /// Check whether all required permissions are granted
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'usageStats': await hasUsageStatsPermission(),
      'overlay': await hasOverlayPermission(),
      'accessibility': await hasAccessibilityPermission(),
    };
  }
}
