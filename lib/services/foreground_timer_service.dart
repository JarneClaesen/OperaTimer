import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:isolate';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

class TimerTaskHandler extends TaskHandler {
  @override
  void onStart(DateTime timestamp) async {
    // Initialize the timer
    print('Foreground service started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // This method is called each time the foreground task is run
    await _updateTimer();
  }

  @override
  void onDestroy(DateTime timestamp) async {
    // Clean up resources if needed
    print('Foreground service destroyed');
  }

  @override
  void onButtonPressed(String id) {
    // Handle notification button press events here
    print('Notification button pressed: $id');
  }

  Future _updateTimer() async {
    final prefs = await SharedPreferences.getInstance();
    int currentTime = prefs.getInt('currentTime') ?? 0;
    bool isRunning = prefs.getBool('isRunning') ?? false;

    if (isRunning) {
      currentTime++;
      await prefs.setInt('currentTime', currentTime);
      print('Foreground service: Updated time to $currentTime');

      // Update the notification
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Orchestra Timer',
        notificationText: 'Time: ${_formatTime(currentTime)}',
      );
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class ForegroundTimerService {
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'orchestra_timer_channel',
        channelName: 'Orchestra Timer Notifications',
        channelDescription: 'Notifications for Orchestra Timer app',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnMyPackageReplaced: true,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      final result = await FlutterForegroundTask.restartService();
      return result == ServiceRequestResult.success;
    } else {
      final result = await FlutterForegroundTask.startService(
        notificationTitle: 'Orchestra Timer',
        notificationText: 'Timer is running',
        notificationIcon: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        callback: startCallback,
      );
      return result == ServiceRequestResult.success;
    }
  }


  static Future<bool> stopForegroundTask() async {
    final result = await FlutterForegroundTask.stopService();
    await FlutterForegroundTask.clearAllData();
    return result == ServiceRequestResult.success;
  }
}