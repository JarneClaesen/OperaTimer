import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'updateTimer':
        await _updateTimer();
        break;
      case 'sendWarningNotification':
        await _sendWarningNotification(inputData);
        break;
    }
    return Future.value(true);
  });
}

Future<void> _updateTimer() async {
  final prefs = await SharedPreferences.getInstance();
  int currentTime = prefs.getInt('currentTime') ?? 0;
  bool isRunning = prefs.getBool('isRunning') ?? false;

  if (isRunning) {
    currentTime++;
    await prefs.setInt('currentTime', currentTime);
  }
}

Future<void> _sendWarningNotification(Map<String, dynamic>? inputData) async {
  final notificationService = NotificationService();
  await notificationService.initialize();

  if (inputData != null && inputData.containsKey('message')) {
    final message = inputData['message'] as String;
    await notificationService.showNotification('Get Ready!', message);
  }
}

class BackgroundNotificationService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'updateTimer',
      'updateTimer',
      frequency: Duration(seconds: 1),
      initialDelay: Duration(seconds: 1),
    );
  }

  static Future<void> scheduleWarningTasks(List<Map<String, dynamic>> warningTasks) async {
    await cancelAllTasks();

    for (var task in warningTasks) {
      final warningTime = DateTime.parse(task['time']);
      final message = task['message'];
      final now = DateTime.now();
      final delay = warningTime.difference(now);

      if (delay.isNegative) continue;

      final taskId = 'sendWarningNotification_${warningTime.millisecondsSinceEpoch}';
      await Workmanager().registerOneOffTask(
        taskId,
        'sendWarningNotification',
        initialDelay: delay,
        inputData: {'message': message},
      );
    }
  }

  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    await Workmanager().registerPeriodicTask(
      'updateTimer',
      'updateTimer',
      frequency: Duration(seconds: 1),
      initialDelay: Duration(seconds: 1),
    );
  }
}
