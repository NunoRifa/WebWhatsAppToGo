import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level callback for background task handler required by flutter_foreground_task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(WhatsGoTaskHandler());
}

class WhatsGoTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Task started
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Keep connection alive tick
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Task destroyed
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop_service') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}

class AppForegroundService {
  static const String _prefKeyServiceEnabled = 'pref_foreground_service_enabled';
  static const String _prefKeyHidePreview = 'pref_hide_notification_preview';

  /// Initialize foreground task settings
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        id: 1001,
        channelId: 'whatsgo_foreground_service',
        channelName: 'WhatsGo Layanan Siaga',
        channelDescription: 'Menjaga koneksi WhatsApp Web tetap aktif di latar belakang',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start Foreground Service with informative persistent notification
  static Future<ServiceRequestResult> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    }

    return FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'WhatsGo Siaga',
      notificationText: 'Menjaga koneksi pesan tetap aktif',
      notificationButtons: [
        const NotificationButton(id: 'open_app', text: 'Buka'),
        const NotificationButton(id: 'stop_service', text: 'Hentikan'),
      ],
      callback: startCallback,
    );
  }

  /// Stop Foreground Service
  static Future<ServiceRequestResult> stopService() async {
    return FlutterForegroundTask.stopService();
  }

  /// Check whether foreground service is running
  static Future<bool> isRunning() async {
    return FlutterForegroundTask.isRunningService;
  }

  /// Check user preference for foreground service
  static Future<bool> isServiceEnabledPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyServiceEnabled) ?? true;
  }

  /// Save user preference for foreground service
  static Future<bool> setServiceEnabledPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_prefKeyServiceEnabled, enabled);
  }

  /// Check user preference for hiding notification preview (privacy)
  static Future<bool> isHidePreviewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyHidePreview) ?? false;
  }

  /// Save user preference for hiding notification preview
  static Future<bool> setHidePreviewPreference(bool hide) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_prefKeyHidePreview, hide);
  }
}

