import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

import 'notification_service.dart';
import '../utils/logger.dart';
import '../utils/time_format.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

class TimerTaskHandler extends TaskHandler {
  final NotificationService _notificationService = NotificationService();
  List<bool> _sentWarningNotifications = [];
  List<bool> _sentPlayTimeNotifications = [];

  // The ongoing foreground-service notification occupies Android notification id
  // 1000 (flutter_foreground_task's default serviceId). Alert ids must avoid
  // that slot: the first play time's warning, posted as id 1000 + 0, would land
  // on the service notification instead of its own — it only buzzes, never
  // reaches the drawer or a paired watch, and the next per-second updateService()
  // call overwrites it. Base the alert ids well clear of 1000 and of each other
  // so every warning/play-time alert gets its own notification slot.
  static const int _warningNotificationBaseId = 100000;
  static const int _playTimeNotificationBaseId = 200000;

  // Working state, kept in memory. It is seeded from the UI-owned control box at
  // onStart, then kept fresh through messages (jump:/playtimes:). We never re-read
  // the control box after startup because, across isolates, our open copy would
  // not see the UI isolate's later disk writes anyway.
  int _startTimeMillis = 0;
  List<int> _playTimes = [];
  // Notification settings, also kept in memory so the UI can change them on the
  // fly (via the settings: message) without restarting the service.
  int _warningTime = 60;
  int _playDuration = 10;
  bool _sendWarningNotifications = true;
  bool _sendPlayTimeNotifications = true;

  // Control box (timerState) is written only by the UI; we read it once at
  // startup. Runtime box (timerRuntime) is written only here. Settings is a
  // UI-owned snapshot we read for notification thresholds.
  Box? _controlBox;
  Box? _runtimeBox;
  Box? _settingsBox;

  static const String controlBoxName = 'timerState';
  static const String runtimeBoxName = 'timerRuntime';
  static const String settingsBoxName = 'settings';

  // True only between a completed onStart and the start of onDestroy. Events
  // (onReceiveData / onRepeatEvent) can fire before Hive is initialized or while
  // the isolate is tearing down; touching Hive then throws
  // "You need to initialize Hive". This gate makes those events no-ops.
  bool _ready = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize Hive for background isolate
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);

    await _ensureBoxes();
    // Seed working state from the control box (fresh from disk on open).
    _startTimeMillis = _controlBox!.get('startTimeMillis') ?? 0;
    _playTimes = List<int>.from(_controlBox!.get('playTimes', defaultValue: []));
    // Seed notification settings; thereafter the UI pushes changes via message.
    _warningTime = _settingsBox!.get('warningTime', defaultValue: 60);
    _playDuration = _settingsBox!.get('playDuration', defaultValue: 10);
    _sendWarningNotifications =
        _settingsBox!.get('sendWarningNotifications', defaultValue: true);
    _sendPlayTimeNotifications =
        _settingsBox!.get('sendPlayTimeNotifications', defaultValue: true);
    // Restore tracking from the runtime box so a service (re)start doesn't
    // re-fire warnings that already went out during the same run.
    _sentWarningNotifications =
        _loadBoolList('hasWarnedForPlayTimes', _playTimes.length);
    _sentPlayTimeNotifications =
        _loadBoolList('hasNotifiedForPlayTimes', _playTimes.length);

    await _notificationService.initialize();
    _ready = true;
    logDebug('Foreground service started by: ${starter.name}');
  }

  Future<void> _ensureBoxes() async {
    _controlBox ??= await Hive.openBox(controlBoxName);
    _runtimeBox ??= await Hive.openBox(runtimeBoxName);
    _settingsBox ??= await Hive.openBox(settingsBoxName);
  }

  List<bool> _loadBoolList(String key, int length) {
    final stored = _runtimeBox!.get(key);
    if (stored is List && stored.length == length) {
      return List<bool>.from(stored);
    }
    return List<bool>.filled(length, false);
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    await _updateTimer();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _ready = false; // Block any in-flight events from touching closed boxes.
    logDebug('Foreground service destroyed (isTimeout: $isTimeout)');
    await Hive.close(); // Close Hive when the service is destroyed
    _controlBox = null;
    _runtimeBox = null;
    _settingsBox = null;
  }

  @override
  void onNotificationButtonPressed(String id) {
    logDebug('Notification button pressed: $id');
  }

  @override
  void onReceiveData(Object data) {
    // Ignore data that arrives before onStart finishes or during teardown —
    // Hive may not be initialized/open yet.
    if (!_ready) return;
    if (data is String) {
      if (data == 'updateTimer') {
        // Trigger an immediate update
        _updateTimer();
      } else if (data.startsWith('jump:')) {
        // The UI shifted the start instant; apply it to our working copy since
        // our open control box never sees the UI isolate's later disk writes.
        final ms = int.tryParse(data.substring('jump:'.length));
        if (ms != null) _applyJump(ms);
      } else if (data.startsWith('playtimes:')) {
        _applyPlayTimes(data.substring('playtimes:'.length));
      } else if (data.startsWith('settings:')) {
        _applySettings(data.substring('settings:'.length));
      }
    }
  }

  // Payload: 'warningTime,playDuration,sendWarning(0|1),sendPlay(0|1)'.
  Future<void> _applySettings(String csv) async {
    final parts = csv.split(',');
    if (parts.length != 4) return;
    _warningTime = int.tryParse(parts[0]) ?? _warningTime;
    _playDuration = int.tryParse(parts[1]) ?? _playDuration;
    _sendWarningNotifications = parts[2] == '1';
    _sendPlayTimeNotifications = parts[3] == '1';
    await _updateTimer();
  }

  Future<void> _applyJump(int startTimeMillis) async {
    _startTimeMillis = startTimeMillis;
    resetNotificationTracking();
    await _updateTimer();
  }

  Future<void> _applyPlayTimes(String csv) async {
    _playTimes = csv.isEmpty
        ? <int>[]
        : csv.split(',').map((e) => int.parse(e)).toList();
    resetNotificationTracking(); // also resizes the tracking lists
    await _updateTimer();
  }

  bool _isUpdating = false;

  Future<void> _updateTimer() async {
    if (!_ready) return; // Isolate not fully started, or tearing down.
    if (_isUpdating) return; // Prevent concurrent execution
    _isUpdating = true;

    try {
      // A hung platform/Hive call must never permanently latch _isUpdating —
      // that would silently freeze the notification for the rest of the run.
      await _runUpdate().timeout(const Duration(seconds: 5));
    } catch (e, stackTrace) {
      logDebug('Error/timeout in _updateTimer: $e');
      logDebug(stackTrace);
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _runUpdate() async {
    await _ensureBoxes();
    final runtimeBox = _runtimeBox!;

    if (_startTimeMillis == 0) return; // Not running.

    final playTimes = _playTimes;
    final warningTime = _warningTime;
    final playDuration = _playDuration;
    final sendWarningNotifications = _sendWarningNotifications;
    final sendPlayTimeNotifications = _sendPlayTimeNotifications;

    if (_sentWarningNotifications.length != playTimes.length) {
      _sentWarningNotifications = List.filled(playTimes.length, false);
    }
    if (_sentPlayTimeNotifications.length != playTimes.length) {
      _sentPlayTimeNotifications = List.filled(playTimes.length, false);
    }

    int currentTime = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(_startTimeMillis))
        .inSeconds;
    if (currentTime < 0) currentTime = 0; // Survive backward clock changes.
    await runtimeBox.put('currentTime', currentTime);
    logDebug('Foreground service: Updated time to $currentTime');

    // Update the notification
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Opera Timer',
      notificationText: formatHms(currentTime),
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
              'Warning', 'You need to play in $timeUntilPlay seconds',
              id: _warningNotificationBaseId + i);
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
              'Play Time', 'It\'s time to play!',
              id: _playTimeNotificationBaseId + i);
          _sentPlayTimeNotifications[i] = true;
        }
      } else {
        if (currentTime >= playTime + playDuration) {
          _sentPlayTimeNotifications[i] = false;
        }
      }
    }

    // Save notification tracking lists
    await runtimeBox.put('hasWarnedForPlayTimes', _sentWarningNotifications);
    await runtimeBox.put('hasNotifiedForPlayTimes', _sentPlayTimeNotifications);
  }

  void resetNotificationTracking() {
    // Size to the current play-time list (it may have just changed).
    _sentWarningNotifications = List.filled(_playTimes.length, false);
    _sentPlayTimeNotifications = List.filled(_playTimes.length, false);
    // Persist the cleared state so a restart doesn't reload stale "already
    // sent" flags from disk.
    _runtimeBox?.put('hasWarnedForPlayTimes', _sentWarningNotifications);
    _runtimeBox?.put('hasNotifiedForPlayTimes', _sentPlayTimeNotifications);
    FlutterForegroundTask.sendDataToMain('notificationTrackingReset');
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
        // New channel id on purpose: Android freezes a channel's importance once
        // it has been created, so bumping importance on the old
        // 'opera_timer_channel' would be ignored on devices that already have it.
        channelId: 'opera_timer_channel_v2',
        channelName: 'Opera Timer Notifications',
        channelDescription: 'Notifications for Opera Timer app',
        // LOW importance buckets the ongoing timer under "Silent", which most
        // Android builds hide/minimize on the lock screen. DEFAULT keeps it
        // visible on the lock screen (like Google Clock); onlyAlertOnce plus no
        // sound/vibration stop it from alerting on every per-second update.
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
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

  // Guards against overlapping start/restart calls (e.g. a resume-triggered
  // start landing on top of an in-flight one), which can wedge the service.
  static bool _isStarting = false;

  /// Starts the foreground service only if it isn't already running. Use this
  /// for "make sure it's alive" checks (e.g. on resume) to avoid the restart
  /// churn that a plain [startForegroundTask] would cause.
  static Future<void> ensureForegroundTaskRunning() async {
    if (!await FlutterForegroundTask.isRunningService) {
      await startForegroundTask();
    }
  }

  static Future<bool> startForegroundTask() async {
    if (_isStarting) {
      logDebug('startForegroundTask already in progress, skipping');
      return false;
    }
    _isStarting = true;
    logDebug('Starting foreground task');
    try {
      if (await FlutterForegroundTask.isRunningService) {
        logDebug('Service is already running, restarting...');
        final result = await FlutterForegroundTask.restartService();
        logDebug('Restart result: $result');
        return result is ServiceRequestSuccess;
      } else {
        logDebug('Starting new foreground service');
        final result = await FlutterForegroundTask.startService(
          notificationTitle: 'Opera Timer',
          notificationText: 'Timer is running',
          // Use the monochrome status-bar icon instead of the launcher icon,
          // which Android masks down to a plain white circle.
          notificationIcon: const NotificationIcon(
            metaDataName:
                'com.orchestratimer.orchestra_timer.NOTIFICATION_ICON',
          ),
          callback: startCallback,
          notificationInitialRoute: '/timer', // Added from 8.17.0
        );
        logDebug('Start result: $result');
        return result is ServiceRequestSuccess;
      }
    } catch (e) {
      logDebug('Error starting foreground task: $e');
      return false;
    } finally {
      _isStarting = false;
    }
  }

  static Future<bool> stopForegroundTask() async {
    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }

  /// Pushes a changed play-time list to the running service isolate so it can
  /// update its working copy and reset notification tracking, without a restart.
  static void updatePlayTimes(List<int> playTimes) {
    FlutterForegroundTask.sendDataToTask('playtimes:${playTimes.join(',')}');
  }

  /// Pushes changed notification settings to the running service isolate so
  /// warning/play-time alerts react on the fly, without a restart.
  static void updateSettings({
    required int warningTime,
    required int playDuration,
    required bool sendWarningNotifications,
    required bool sendPlayTimeNotifications,
  }) {
    FlutterForegroundTask.sendDataToTask(
        'settings:$warningTime,$playDuration,'
        '${sendWarningNotifications ? 1 : 0},'
        '${sendPlayTimeNotifications ? 1 : 0}');
  }
}