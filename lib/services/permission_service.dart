import 'dart:io' show Platform;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class PermissionService {
  Future<void> requestPermissions() async {
    // Request notification permission
    if (await Permission.notification.status.isDenied) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // Request ignore battery optimization
    if (!(await FlutterForegroundTask.isIgnoringBatteryOptimizations)) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (Platform.isAndroid) {
      try {
        await AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);
      } catch (e) {
        print("Error opening battery settings: $e");
        throw Exception('Unable to open battery settings');
      }
    } else {
      throw Exception('Battery optimization settings are only available on Android devices');
    }
  }
}