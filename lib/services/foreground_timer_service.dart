import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:isolate';

import 'notification_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

class TimerTaskHandler extends TaskHandler {
  NotificationService _notificationService = NotificationService();
  Set<int> _sentWarningNotifications = {};
  Set<int> _sentPlayTimeNotifications = {};

  @override
  void onStart(DateTime timestamp) async {
    await _notificationService.initialize();
    // don't call _update timer here
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

  @override
  void onReceiveData(Object? data) {
    if (data is String && data == 'resetNotificationTracking') {
      resetNotificationTracking();
    }
  }

  Future _updateTimer() async {
    final prefs = await SharedPreferences.getInstance();
    bool isRunning = prefs.getBool('isRunning') ?? false;
    int startTimeMillis = prefs.getInt('startTimeMillis') ?? 0;

    List<String> playTimesStrings = prefs.getStringList('playTimes') ?? [];
    List<int> playTimes = playTimesStrings.map((e) => int.parse(e)).toList();

    int warningTime = prefs.getInt('warningTime') ?? 60;
    int playDuration = prefs.getInt('playDuration') ?? 10;
    bool sendWarningNotifications = prefs.getBool('sendWarningNotifications') ?? true;
    bool sendPlayTimeNotifications = prefs.getBool('sendPlayTimeNotifications') ?? true;

    if ((isRunning && startTimeMillis != 0)) {
      int currentTime = isRunning
          ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startTimeMillis)).inSeconds
          : prefs.getInt('currentTime') ?? 0;
      await prefs.setInt('currentTime', currentTime);
      print('Foreground service: Updated time to $currentTime');

      // Update the notification
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Opera Timer',
        notificationText: _formatTime(currentTime),
      );

      // Check for warnings and play times
      for (int i = 0; i < playTimes.length; i++) {
        int playTime = playTimes[i];
        int timeUntilPlay = playTime - currentTime;

        // Check for warning time
        if (timeUntilPlay <= warningTime && timeUntilPlay > 0 && sendWarningNotifications) {
          if (!_sentWarningNotifications.contains(i) && timeUntilPlay <= 5) {
            await _notificationService.showNotification('Warning', 'You need to play in $warningTime seconds');
            _sentWarningNotifications.add(i);
          }
        } else {
          _sentWarningNotifications.remove(i);
        }

        // Check for play time
        if (currentTime >= playTime && currentTime < playTime + playDuration && sendPlayTimeNotifications) {
          if (!_sentPlayTimeNotifications.contains(i) && currentTime - playTime < 5) {
            await _notificationService.showNotification('Play Time', 'It\'s time to play!');
            _sentPlayTimeNotifications.add(i);
          }
        } else {
          _sentPlayTimeNotifications.remove(i);
        }
      }
    }
  }

  void resetNotificationTracking() {
    _sentWarningNotifications.clear();
    _sentPlayTimeNotifications.clear();
    // Send data to main isolate to confirm reset
    FlutterForegroundTask.sendDataToMain('notificationTrackingReset');
  }



  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class ForegroundTimerService {
  static Future<void> requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermissionStatus =
    await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'opera_timer_channel',
        channelName: 'Opera Timer Notifications',
        channelDescription: 'Notifications for Opera Timer app',
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
    print('Starting foreground task');
    try {
      if (await FlutterForegroundTask.isRunningService) {
        print('Service is already running, restarting...');
        final result = await FlutterForegroundTask.restartService();
        print('Restart result: $result');
        return result == ServiceRequestResult.success;
      } else {
        print('Starting new foreground service');
        final result = await FlutterForegroundTask.startService(
          notificationTitle: 'Opera Timer',
          notificationText: 'Timer is running',
          notificationIcon: const NotificationIconData(
            resType: ResourceType.mipmap,
            resPrefix: ResourcePrefix.ic,
            name: 'launcher',
          ),
          callback: startCallback,
        );
        print('Start result: $result');
        return result == ServiceRequestResult.success;
      }
    } catch (e) {
      print('Error starting foreground task: $e');
      return false;
    }
  }

  static Future<bool> stopForegroundTask() async {
    final result = await FlutterForegroundTask.stopService();
    // await FlutterForegroundTask.clearAllData();
    return result == ServiceRequestResult.success;
  }

  static void resetNotificationTracking() {
    FlutterForegroundTask.sendDataToTask('resetNotificationTracking');
  }
}