import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'updateTimer':
        await _updateTimer();
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
    print('Background service: Updated time to $currentTime');
  }
}

class BackgroundTimerService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> startPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      'updateTimer',
      'updateTimer',
      frequency: Duration(seconds: 15),
      initialDelay: Duration(seconds: 15),
    );
  }

  static Future<void> stopPeriodicTask() async {
    await Workmanager().cancelByUniqueName('updateTimer');
  }
}
