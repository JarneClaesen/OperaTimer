import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'sendWarningNotification') {
      final notificationService = NotificationService();
      await notificationService.initialize();

      if (inputData != null && inputData.containsKey('message')) {
        final message = inputData['message'] as String;
        await notificationService.showNotification('Get Ready!', message);
      }
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
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
  }
}
