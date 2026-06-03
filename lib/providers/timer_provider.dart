import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import '../services/foreground_timer_service.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';

class TimerProvider with ChangeNotifier, WidgetsBindingObserver {
  static const String settingsBoxName = 'settings';
  // `timerState` is the control box: only the UI isolate writes it (run command,
  // start instant, play times, opera name). `timerRuntime` is owned by the
  // foreground-service isolate, which is the only writer of the per-tick
  // `currentTime` and the notification-tracking flags. Splitting the two writers
  // onto separate box files removes the concurrent multi-isolate write hazard.
  static const String timerStateBoxName = 'timerState';
  static const String timerRuntimeBoxName = 'timerRuntime';

  static const String warningTimeKey = 'warningTime';
  static const String playDurationKey = 'playDuration';
  static const String currentTimeKey = 'currentTime';
  static const String isRunningKey = 'isRunning';
  static const String startTimeMillisKey = 'startTimeMillis';
  static const String playTimesKey = 'playTimes';
  static const String sendWarningNotificationsKey =
      'sendWarningNotifications';
  static const String sendPlayTimeNotificationsKey =
      'sendPlayTimeNotifications';
  static const String currentOperaNameKey = 'currentOperaName';
  static const String hasWarnedForPlayTimesKey = 'hasWarnedForPlayTimes';
  static const String hasNotifiedForPlayTimesKey = 'hasNotifiedForPlayTimes';

  int _currentTime = 0;
  int _warningTime = 60; // Default: 1 minute before play time
  int _playDuration = 10; // Default: 10 seconds for play time message
  int _jumpSeconds = 1;
  List<int> _playTimes = [];
  bool _isWarningActive = false;
  bool _isPlayTimeActive = false;
  bool _isRunning = false;
  bool _isOnTimerScreen = false;
  bool _sendWarningNotifications = true;
  bool _sendPlayTimeNotifications = true;
  final NotificationService _notificationService = NotificationService();
  String? _currentOperaName;
  DateTime? _startTime;
  bool _showGlowingBorders = true;
  bool _showJumpButtons = true;
  Timer? _periodicTimer;
  void Function(Object)? _taskDataCallback;

  TimerProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initializeHive();
    _notificationService.initialize();
    _loadSettings();
    _loadTimerState();
    startPeriodicUpdate();
    initForegroundTaskListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // OEMs can freeze the main-isolate timer while backgrounded, so re-arm
      // the UI tick and recompute immediately rather than waiting for the next
      // (possibly never-arriving) fire.
      startPeriodicUpdate();
      updateTimer();
      // The foreground service may have been killed while we were away; bring
      // it back without restarting an already-healthy one.
      if (_isRunning) {
        ForegroundTimerService.ensureForegroundTaskRunning();
      }
    }
  }

  Future<void> _initializeHive() async {
    // Initialize Hive if not already initialized
    if (!Hive.isAdapterRegistered(0)) {
      final appDocDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocDir.path);
    }
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox(settingsBoxName);
    _warningTime = box.get(warningTimeKey, defaultValue: 60);
    _playDuration = box.get(playDurationKey, defaultValue: 10);
    _sendWarningNotifications =
        box.get(sendWarningNotificationsKey, defaultValue: true);
    _sendPlayTimeNotifications =
        box.get(sendPlayTimeNotificationsKey, defaultValue: true);
    _jumpSeconds = box.get('jumpSeconds', defaultValue: 1);
    _showGlowingBorders = box.get('showGlowingBorders', defaultValue: true);
    _showJumpButtons = box.get('showJumpButtons', defaultValue: true);
    notifyListeners();
  }

  Future<void> _loadTimerState() async {
    final box = await Hive.openBox(timerStateBoxName);
    final runtimeBox = await Hive.openBox(timerRuntimeBoxName);
    _isRunning = box.get(isRunningKey, defaultValue: false);
    int? startTimeMillis = box.get(startTimeMillisKey);
    if (startTimeMillis != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    }
    _playTimes = List<int>.from(box.get(playTimesKey, defaultValue: []));
    _currentOperaName = box.get(currentOperaNameKey);
    // currentTime lives in the service-owned runtime box; on a cold start this
    // restores the last value the service persisted (e.g. while paused). When
    // running, the periodic tick immediately recomputes it from _startTime.
    _currentTime = runtimeBox.get(currentTimeKey, defaultValue: 0);
    notifyListeners();
  }

  Future<void> _saveTimerState() async {
    // Writes only control fields. currentTime and notification tracking belong
    // to the runtime box (service-owned) and are never written here.
    final box = await Hive.openBox(timerStateBoxName);
    await box.put(isRunningKey, _isRunning);
    if (_startTime != null) {
      await box.put(startTimeMillisKey, _startTime!.millisecondsSinceEpoch);
    } else {
      await box.delete(startTimeMillisKey);
    }
    await box.put(playTimesKey, _playTimes);
    await box.put(currentOperaNameKey, _currentOperaName);
  }

  /// Resets the service-owned runtime box (currentTime + tracking). Only safe to
  /// call when the foreground service is NOT running — i.e. after stopping it —
  /// so the two isolates never write this box concurrently.
  Future<void> _resetRuntime() async {
    final runtimeBox = await Hive.openBox(timerRuntimeBoxName);
    final reset = List<bool>.filled(_playTimes.length, false);
    await runtimeBox.put(currentTimeKey, 0);
    await runtimeBox.put(hasWarnedForPlayTimesKey, reset);
    await runtimeBox.put(hasNotifiedForPlayTimesKey, reset);
  }

  void startPeriodicUpdate() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      updateTimer();
    });
  }

  int get currentTime => _currentTime;
  bool get isWarning => _isWarningActive;
  bool get isPlayTime => _isPlayTimeActive;
  bool get isRunning => _isRunning;
  List<int> get playTimes => _playTimes;
  bool get isOnTimerScreen => _isOnTimerScreen;
  String? get currentOperaName => _currentOperaName;
  int get warningTime => _warningTime;
  int get playDuration => _playDuration;
  bool get sendWarningNotifications => _sendWarningNotifications;
  bool get sendPlayTimeNotifications => _sendPlayTimeNotifications;
  int get jumpSeconds => _jumpSeconds;
  bool get showGlowingBorders => _showGlowingBorders;
  bool get showJumpButtons => _showJumpButtons;

  void setOnTimerScreen(bool value) {
    _isOnTimerScreen = value;
    notifyListeners();
  }

  int get currentPlayTimeIndex {
    return _playTimes.indexWhere((time) => time > _currentTime);
  }

  int? get nextPlayTime {
    for (int time in _playTimes) {
      if (time > _currentTime) {
        return time;
      }
    }
    return null;
  }

  void setCurrentOpera(String operaName, List<int> playTimes) {
    if (_currentOperaName != operaName ||
        !listEquals(_playTimes, playTimes)) {
      _currentOperaName = operaName;
      setPlayTimes(playTimes);
      _saveTimerState(); // Save the current opera name
    }
    notifyListeners();
  }

  void setPlayTimes(List<int> playTimes) {
    if (!listEquals(_playTimes, playTimes)) {
      _playTimes = playTimes;
      _saveTimerState();
      // The warning/play-time schedule changed. If the service is live, hand it
      // the new list over the data channel; otherwise clear the runtime box
      // ourselves while no other isolate is writing it.
      if (_isRunning) {
        ForegroundTimerService.updatePlayTimes(playTimes);
      } else {
        _resetRuntime();
      }
      notifyListeners();
    }
  }

  /// Pushes the notification-affecting settings to the running service so
  /// changes take effect on the fly (no restart). No-op when not running; the
  /// service re-seeds from disk on its next start anyway.
  void _pushSettingsToService() {
    if (_isRunning) {
      ForegroundTimerService.updateSettings(
        warningTime: _warningTime,
        playDuration: _playDuration,
        sendWarningNotifications: _sendWarningNotifications,
        sendPlayTimeNotifications: _sendPlayTimeNotifications,
      );
    }
  }

  Future<void> setWarningTime(int seconds) async {
    _warningTime = seconds;
    final box = await Hive.openBox(settingsBoxName);
    await box.put(warningTimeKey, seconds);
    _pushSettingsToService();
    notifyListeners();
  }

  Future<void> setPlayDuration(int seconds) async {
    _playDuration = seconds;
    final box = await Hive.openBox(settingsBoxName);
    await box.put(playDurationKey, seconds);
    _pushSettingsToService();
    notifyListeners();
  }

  Future<void> setSendWarningNotifications(bool value) async {
    _sendWarningNotifications = value;
    final box = await Hive.openBox(settingsBoxName);
    await box.put(sendWarningNotificationsKey, value);
    _pushSettingsToService();
    notifyListeners();
  }

  Future<void> setSendPlayTimeNotifications(bool value) async {
    _sendPlayTimeNotifications = value;
    final box = await Hive.openBox(settingsBoxName);
    await box.put(sendPlayTimeNotificationsKey, value);
    _pushSettingsToService();
    notifyListeners();
  }

  Future<void> setJumpSeconds(int seconds) async {
    _jumpSeconds = seconds;
    final box = await Hive.openBox(settingsBoxName);
    await box.put('jumpSeconds', seconds);
    notifyListeners();
  }

  Future<void> setShowGlowingBorders(bool value) async {
    _showGlowingBorders = value;
    final box = await Hive.openBox(settingsBoxName);
    await box.put('showGlowingBorders', value);
    notifyListeners();
  }

  Future<void> setShowJumpButtons(bool value) async {
    _showJumpButtons = value;
    final box = await Hive.openBox(settingsBoxName);
    await box.put('showJumpButtons', value);
    notifyListeners();
  }

  Future<void> startTimer() async {
    if (_isRunning) return;
    _isRunning = true;
    _startTime = DateTime.now().subtract(Duration(seconds: _currentTime));
    await _saveTimerState();
    notifyListeners();
    await ForegroundTimerService.startForegroundTask();
  }

  Future<void> pauseTimer() async {
    if (!_isRunning) return;
    _isRunning = false;
    _startTime = null;
    await _saveTimerState();
    notifyListeners();
    await ForegroundTimerService.stopForegroundTask();
  }

  Future<void> stopTimer() async {
    _currentTime = 0;
    _isWarningActive = false;
    _isPlayTimeActive = false;
    _isRunning = false;
    _startTime = null;
    await _saveTimerState();
    notifyListeners();
    await ForegroundTimerService.stopForegroundTask();
    // Service is stopped now, so we can safely clear its runtime box.
    await _resetRuntime();
  }

  void initForegroundTaskListener() {
    _taskDataCallback = (data) {
      if (data is String && data == 'notificationTrackingReset') {
        logDebug('Notification tracking reset confirmed');
      }
    };
    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
    if (_taskDataCallback != null) {
      FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
    }
    super.dispose();
  }

  Future<void> jumpForward() => _jumpBy(_jumpSeconds);

  Future<void> jumpBackward() => _jumpBy(-_jumpSeconds);

  /// Shifts the running timer by [deltaSeconds]. The UI's own clock updates
  /// instantly; the foreground service is shifted by the same amount over the
  /// data channel. The new start instant is also persisted to the control box,
  /// so a later legitimate service (re)start re-reads it from disk and stays in
  /// sync even if a single message is ever missed.
  Future<void> _jumpBy(int deltaSeconds) async {
    if (!_isRunning || _startTime == null) return;
    final now = DateTime.now();
    _currentTime = max(0, now.difference(_startTime!).inSeconds + deltaSeconds);
    _startTime = now.subtract(Duration(seconds: _currentTime));
    await _saveTimerState();
    _updateWarningState();
    notifyListeners();
    FlutterForegroundTask.sendDataToTask(
        'jump:${_startTime!.millisecondsSinceEpoch}');
  }

  void _updateWarningState() {
    bool warning = false;
    bool playTime = false;
    for (final time in _playTimes) {
      final timeUntilPlay = time - _currentTime;
      if (timeUntilPlay <= _warningTime && timeUntilPlay > 0) {
        warning = true;
      }
      if (_currentTime >= time && _currentTime < time + _playDuration) {
        playTime = true;
      }
    }
    _isWarningActive = warning;
    _isPlayTimeActive = playTime;
  }

  void updateTimer() {
    if (_isRunning && _startTime != null) {
      // Clamp at zero so a backward wall-clock correction (NTP/DST) over a long
      // session can't drive the displayed time negative.
      _currentTime = max(0, DateTime.now().difference(_startTime!).inSeconds);
      // The foreground-service isolate owns the per-second `currentTime`
      // persistence; we only recompute it locally here to drive the UI and
      // warning state, avoiding concurrent multi-isolate writes to the box.
      _updateWarningState();
      notifyListeners();
    }
  }
}
