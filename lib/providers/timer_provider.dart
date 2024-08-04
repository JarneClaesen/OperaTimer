import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';

class TimerProvider with ChangeNotifier {
  static const String settingsBoxName = 'settings';
  static const String warningTimeKey = 'warningTime';
  static const String playDurationKey = 'playDuration';

  Timer? _timer;
  int _currentTime = 0;
  int _warningTime = 60; // Default: 1 minute before play time
  int _playDuration = 10; // Default: 10 seconds for play time message
  List<int> _playTimes = [];
  int _nextPlayIndex = 0;
  bool _isWarningActive = false;
  bool _isPlayTimeActive = false;
  bool _isRunning = false;
  bool _isOnTimerScreen = false;
  final NotificationService _notificationService = NotificationService();
  String? _currentOperaName;
  List<bool> _hasWarnedForPlayTimes = [];

  TimerProvider() {
    _notificationService.initialize();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox(settingsBoxName);
    _warningTime = box.get(warningTimeKey, defaultValue: 60);
    _playDuration = box.get(playDurationKey, defaultValue: 10);
    notifyListeners();
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
      _nextPlayIndex = 0;
      _isWarningActive = false;
      _isPlayTimeActive = false;
      _isRunning = false;
      _hasWarnedForPlayTimes = List.filled(playTimes.length, false);
      _timer?.cancel();
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

  Future<void> startTimer() async {
    if (_isRunning) return;
    _isRunning = true;
    _checkWarningsAndPlayTimes();
    notifyListeners();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _currentTime++;
      _checkWarningsAndPlayTimes();
      notifyListeners();
    });

    // Schedule background tasks for all warning times
    await _scheduleWarningTasks();
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    _currentTime = 0;
    _nextPlayIndex = 0;
    _isWarningActive = false;
    _isPlayTimeActive = false;
    _isRunning = false;
    _hasWarnedForPlayTimes = List.filled(_playTimes.length, false);
    notifyListeners();

    // Cancel background tasks
    await BackgroundService.cancelAllTasks();
  }

  Future<void> _scheduleWarningTasks() async {
    final now = DateTime.now();
    final warningTasks = _playTimes.asMap().entries.map((entry) {
      final index = entry.key;
      final playTime = entry.value;
      final warningTime = now.add(Duration(seconds: playTime - _currentTime - _warningTime));
      final message = _formatWarningMessage(_warningTime);
      return {
        'index': index,
        'time': warningTime.toIso8601String(),
        'message': message,
      };
    }).toList();

    await BackgroundService.scheduleWarningTasks(warningTasks);
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
          // You can add any additional logic here if needed when a warning becomes active
        }
      }
      // Check for play time
      else if (_currentTime >= playTime && _currentTime < playTime + _playDuration) {
        anyPlayTimeActive = true;
      }
    }

    _isWarningActive = anyWarningActive;
    _isPlayTimeActive = anyPlayTimeActive;

    notifyListeners();
  }
}
