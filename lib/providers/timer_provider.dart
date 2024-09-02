import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/foreground_timer_service.dart';
import '../services/notification_service.dart';

class TimerProvider with ChangeNotifier {
  static const String settingsBoxName = 'settings';
  static const String warningTimeKey = 'warningTime';
  static const String playDurationKey = 'playDuration';
  static const String currentTimeKey = 'currentTime';
  static const String isRunningKey = 'isRunning';
  static const String sendWarningNotificationsKey = 'sendWarningNotifications';
  static const String sendPlayTimeNotificationsKey = 'sendPlayTimeNotifications';

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
    _notificationService.initialize();
    _loadSettings();
    _loadTimerState();
    startPeriodicUpdate();
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox(settingsBoxName);
    _warningTime = box.get(warningTimeKey, defaultValue: 60);
    _playDuration = box.get(playDurationKey, defaultValue: 10);
    _sendWarningNotifications = box.get(sendWarningNotificationsKey, defaultValue: true);
    _sendPlayTimeNotifications = box.get(sendPlayTimeNotificationsKey, defaultValue: true);
    _jumpSeconds = box.get('jumpSeconds', defaultValue: 1);
    _showGlowingBorders = box.get('showGlowingBorders', defaultValue: true);
    _showJumpButtons = box.get('showJumpButtons', defaultValue: true);
    notifyListeners();
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTime = prefs.getInt('currentTime') ?? 0;
    _isRunning = prefs.getBool('isRunning') ?? false;
    int? startTimeMillis = prefs.getInt('startTimeMillis');
    if (startTimeMillis != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    }
    notifyListeners();
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentTime', _currentTime);
    await prefs.setBool('isRunning', _isRunning);
    if (_startTime != null) {
      await prefs.setInt('startTimeMillis', _startTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('startTimeMillis');
    }
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
    if (_currentOperaName != operaName || !listEquals(_playTimes, playTimes)) {
      _currentOperaName = operaName;
      setPlayTimes(playTimes);
    }
    notifyListeners();
  }

  void setPlayTimes(List<int> playTimes) {
    if (!listEquals(_playTimes, playTimes)) {
      _playTimes = playTimes;
      _currentTime = 0;
      _isWarningActive = false;
      _isPlayTimeActive = false;
      _isRunning = false;
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

  void setJumpSeconds(int seconds) async {
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

  Future setShowJumpButtons(bool value) async {
    _showJumpButtons = value;
    final box = await Hive.openBox(settingsBoxName);
    await box.put('showJumpButtons', value);
    notifyListeners();
  }

  Future<void> startTimer() async {
    if (_isRunning) return;
    _isRunning = true;
    _startTime = DateTime.now().subtract(Duration(seconds: _currentTime));
    _checkWarningsAndPlayTimes();
    await _saveTimerState();
    notifyListeners();
    await ForegroundTimerService.startForegroundTask();
  }

  Future<void> pauseTimer() async{
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
    _saveTimerState();
    notifyListeners();

    // Stop foreground task
    await ForegroundTimerService.stopForegroundTask();
  }

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


  String _formatWarningMessage(int seconds) {
    if (seconds < 60) {
      return '$seconds second${seconds != 1 ? 's' : ''} until you have to play!';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;

      String message = '$minutes minute${minutes > 1 ? 's' : ''}';

      if (remainingSeconds > 0) {
        message += ' and $remainingSeconds second${remainingSeconds != 1 ? 's' : ''}';
      }

      return '$message until you have to play!';
    }
  }

  void _checkWarningsAndPlayTimes() {
    bool anyWarningActive = false;
    bool anyPlayTimeActive = false;

    for (int i = 0; i < _playTimes.length; i++) {
      int playTime = _playTimes[i];
      int timeUntilPlay = playTime - _currentTime;

      // Check for warning time
      if (timeUntilPlay <= _warningTime && timeUntilPlay > 0) {
        anyWarningActive = true;
        if (!_hasWarnedForPlayTimes[i]) {
          _hasWarnedForPlayTimes[i] = true;
          if (_sendWarningNotifications) {
            _notificationService.showNotification('Warning', 'You need to play in $_warningTime seconds');
          }
        }
      }
      // Check for play time
      else if (_currentTime >= playTime && _currentTime < playTime + _playDuration) {
        anyPlayTimeActive = true;
        if (!_hasNotifiedForPlayTimes[i]) { // Add this check
          _hasNotifiedForPlayTimes[i] = true; // Set the flag
          if (_sendPlayTimeNotifications) {
            _notificationService.showNotification('Play Time', 'It\'s time to play!');
          }
        }
      }
      else {
        // Reset the notification flag when outside the play time window
        _hasNotifiedForPlayTimes[i] = false;
      }
    }

    _isWarningActive = anyWarningActive;
    _isPlayTimeActive = anyPlayTimeActive;

    notifyListeners();
  }

  // This method will be called by the background service to update the timer
  void updateTimer() {
    if (_isRunning && _startTime != null) {
      _currentTime = DateTime.now().difference(_startTime!).inSeconds;
      _checkWarningsAndPlayTimes();
      _saveTimerState();
      notifyListeners();
    }
  }
}
