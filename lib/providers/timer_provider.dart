import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import '../services/foreground_timer_service.dart';
import '../services/notification_service.dart';

class TimerProvider with ChangeNotifier {
  static const String settingsBoxName = 'settings';
  static const String timerStateBoxName = 'timerState';

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
  List<bool> _hasWarnedForPlayTimes = [];
  List<bool> _hasNotifiedForPlayTimes = [];
  DateTime? _startTime;
  bool _showGlowingBorders = true;
  bool _showJumpButtons = true;
  Timer? _debounceTimer;

  TimerProvider() {
    _initializeHive();
    _notificationService.initialize();
    _loadSettings();
    _loadTimerState();
    startPeriodicUpdate();
    initForegroundTaskListener();
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
    _currentTime = box.get(currentTimeKey, defaultValue: 0);
    _isRunning = box.get(isRunningKey, defaultValue: false);
    int? startTimeMillis = box.get(startTimeMillisKey);
    if (startTimeMillis != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    }
    _playTimes = List<int>.from(box.get(playTimesKey, defaultValue: []));
    _currentOperaName = box.get(currentOperaNameKey);
    _hasWarnedForPlayTimes =
    List<bool>.from(box.get(hasWarnedForPlayTimesKey, defaultValue: List<bool>.filled(_playTimes.length, false)));
    _hasNotifiedForPlayTimes =
    List<bool>.from(box.get(hasNotifiedForPlayTimesKey, defaultValue: List<bool>.filled(_playTimes.length, false)));
    notifyListeners();
  }

  Future<void> _saveTimerState() async {
    final box = await Hive.openBox(timerStateBoxName);
    await box.put(currentTimeKey, _currentTime);
    await box.put(isRunningKey, _isRunning);
    if (_startTime != null) {
      await box.put(startTimeMillisKey, _startTime!.millisecondsSinceEpoch);
    } else {
      await box.delete(startTimeMillisKey);
    }
    await box.put(playTimesKey, _playTimes);
    await box.put(warningTimeKey, _warningTime);
    await box.put(playDurationKey, _playDuration);
    await box.put(sendWarningNotificationsKey, _sendWarningNotifications);
    await box.put(sendPlayTimeNotificationsKey, _sendPlayTimeNotifications);
    await box.put(currentOperaNameKey, _currentOperaName);
    await box.put(hasWarnedForPlayTimesKey, _hasWarnedForPlayTimes);
    await box.put(hasNotifiedForPlayTimesKey, _hasNotifiedForPlayTimes);
  }

  void startPeriodicUpdate() {
    Timer.periodic(Duration(seconds: 1), (timer) {
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
      _hasWarnedForPlayTimes = List.filled(playTimes.length, false);
      _hasNotifiedForPlayTimes = List.filled(playTimes.length, false);
      _saveTimerState();
      notifyListeners();
    }
  }

  Future<void> setWarningTime(int seconds) async {
    _warningTime = seconds;
    final box = await Hive.openBox(settingsBoxName);
    await box.put(warningTimeKey, seconds);
    notifyListeners();
  }

  Future<void> setPlayDuration(int seconds) async {
    _playDuration = seconds;
    final box = await Hive.openBox(settingsBoxName);
    await box.put(playDurationKey, seconds);
    notifyListeners();
  }

  Future<void> setSendWarningNotifications(bool value) async {
    _sendWarningNotifications = value;
    final box = await Hive.openBox(settingsBoxName);
    await box.put(sendWarningNotificationsKey, value);
    notifyListeners();
  }

  Future<void> setSendPlayTimeNotifications(bool value) async {
    _sendPlayTimeNotifications = value;
    final box = await Hive.openBox(settingsBoxName);
    await box.put(sendPlayTimeNotificationsKey, value);
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
    _hasWarnedForPlayTimes = List.filled(_playTimes.length, false);
    _hasNotifiedForPlayTimes = List.filled(_playTimes.length, false);
    await _saveTimerState();
    notifyListeners();
    await ForegroundTimerService.stopForegroundTask();
  }

  void initForegroundTaskListener() {
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is String && data == 'notificationTrackingReset') {
        print('Notification tracking reset confirmed');
      }
    });
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback((data) {});
    super.dispose();
  }

  // Workaround. Should be with FlutterForegroundTask.sendDataToTask('updateTimer');
  // but doesnt work
  Future<void> jumpForward() async {
    if (_isRunning) {
      await pauseTimer();
      _currentTime += _jumpSeconds;
      await startTimer();
    }
  }
  Future<void> jumpBackward() async {
    if (_isRunning) {
      await pauseTimer();
      _currentTime = max(0, _currentTime - _jumpSeconds);
      await startTimer();
    }
  }

  Future<void> debouncedJumpForward() async {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      await jumpForward();
    });
  }

  Future<void> debouncedJumpBackward() async {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      await jumpBackward();
    });
  }

  void updateTimer() {
    if (_isRunning && _startTime != null) {
      _currentTime = DateTime.now().difference(_startTime!).inSeconds;
      _saveTimerState();
      notifyListeners();
    }
  }
}
