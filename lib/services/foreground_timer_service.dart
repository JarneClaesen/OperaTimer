import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

import 'notification_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

class TimerTaskHandler extends TaskHandler {
  NotificationService _notificationService = NotificationService();
  List<bool> _sentWarningNotifications = [];
  List<bool> _sentPlayTimeNotifications = [];

  static const String timerStateBoxName = 'timerState';

  @override
  Future<void> onStart(DateTime timestamp) async {
    // Initialize Hive for background isolate
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);

    await _notificationService.initialize();
    print('Foreground service started');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    await _updateTimer();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('Foreground service destroyed');
    await Hive.close(); // Close Hive when the service is destroyed
  }

  @override
  void onButtonPressed(String id) {
    print('Notification button pressed: $id');
  }

  @override
  void onDataReceived(dynamic data) {
    if (data is String && data == 'resetNotificationTracking') {
      resetNotificationTracking();
    }
  }

  Future<void> _updateTimer() async {
    final box = await Hive.openBox(timerStateBoxName);

    bool isRunning = box.get('isRunning', defaultValue: false);
    int startTimeMillis = box.get('startTimeMillis') ?? 0;

    List<dynamic> playTimesList = box.get('playTimes', defaultValue: []);
    List<int> playTimes = List<int>.from(playTimesList);

    int warningTime = box.get('warningTime', defaultValue: 60);
    int playDuration = box.get('playDuration', defaultValue: 10);
    bool sendWarningNotifications =
    box.get('sendWarningNotifications', defaultValue: true);
    bool sendPlayTimeNotifications =
    box.get('sendPlayTimeNotifications', defaultValue: true);

    if (_sentWarningNotifications.length != playTimes.length) {
      _sentWarningNotifications = List.filled(playTimes.length, false);
    }
    if (_sentPlayTimeNotifications.length != playTimes.length) {
      _sentPlayTimeNotifications = List.filled(playTimes.length, false);
    }

    if (isRunning && startTimeMillis != 0) {
      int currentTime = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(startTimeMillis))
          .inSeconds;
      await box.put('currentTime', currentTime);
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
        if (timeUntilPlay <= warningTime &&
            timeUntilPlay > 0 &&
            sendWarningNotifications) {
          if (!_sentWarningNotifications[i]) {
            await _notificationService.showNotification(
                'Warning', 'You need to play in $timeUntilPlay seconds');
            _sentWarningNotifications[i] = true;
          }
        } else {
          _sentWarningNotifications[i] = false;
        }

        // Check for play time
        if (currentTime >= playTime &&
            currentTime < playTime + playDuration &&
            sendPlayTimeNotifications) {
          if (!_sentPlayTimeNotifications[i]) {
            await _notificationService.showNotification(
                'Play Time', 'It\'s time to play!');
            _sentPlayTimeNotifications[i] = true;
          }
        } else {
          if (currentTime >= playTime + playDuration) {
            _sentPlayTimeNotifications[i] = false;
          }
        }
      }

      // Save notification tracking lists
      await box.put('hasWarnedForPlayTimes', _sentWarningNotifications);
      await box.put('hasNotifiedForPlayTimes', _sentPlayTimeNotifications);
    }
  }

  void resetNotificationTracking() {
    _sentWarningNotifications =
        List.filled(_sentWarningNotifications.length, false);
    _sentPlayTimeNotifications =
        List.filled(_sentPlayTimeNotifications.length, false);
    FlutterForegroundTask.sendDataToMain('notificationTrackingReset');
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class ForegroundTimerService {
  static Future<void> requestPermissions() async {
    final NotificationPermission notificationPermissionStatus =
    await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
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
        return result == ServiceRequestResult.success();
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
        return result == ServiceRequestResult.success();
      }
    } catch (e) {
      print('Error starting foreground task: $e');
      return false;
    }
  }

  static Future<bool> stopForegroundTask() async {
    final result = await FlutterForegroundTask.stopService();
    return result == ServiceRequestResult.success();
  }

  static void resetNotificationTracking() {
    FlutterForegroundTask.sendDataToTask('resetNotificationTracking');
  }
}
