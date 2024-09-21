import 'dart:io' show Platform;

import 'package:android_intent/android_intent.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/timer_provider.dart';
import '../providers/brightness_provider.dart';
import '../services/foreground_timer_service.dart';
import '../services/permission_service.dart';
import '../widgets/glowing_borders.dart';
import '../widgets/timer_screen/settings_dialog.dart';
import '../widgets/timer_screen/timeline_item.dart';
import '../widgets/timer_screen/timer_controls.dart';
import '../widgets/timer_screen/brightness_slider.dart';
import '../widgets/timer_screen/warning_message.dart';
import '../services/device_check_service.dart';
import 'package:package_info_plus/package_info_plus.dart';


class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final DeviceCheckService _deviceCheckService = DeviceCheckService();
  final PermissionService _permissionService = PermissionService();
  bool _isNormalMode = false;
  bool _isSpeakerVolumeOn = false;
  bool _isBluetoothConnected = false;
  bool _hasNotificationPermission = false;
  bool _hasBatteryOptimizationPermission = false;
  bool _isCheckComplete = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TimerProvider>(context, listen: false).setOnTimerScreen(true);
      _checkDeviceStatus();
    });
  }

  @override
  void dispose() {
    Provider.of<TimerProvider>(context, listen: false).setOnTimerScreen(false);
    super.dispose();
  }

  Future<void> _checkDeviceStatus() async {
    final soundMode = await _deviceCheckService.checkSoundMode();
    final speakerVolume = await _deviceCheckService.checkSpeakerVolume();
    final bluetoothConnection = await _deviceCheckService.checkBluetoothConnection();

    // Check and request permissions
    await _permissionService.requestPermissions();

    // Check permission statuses after requesting
    final notificationPermission = await Permission.notification.status.isGranted;
    final batteryOptimizationPermission = await FlutterForegroundTask.isIgnoringBatteryOptimizations;

    setState(() {
      _isNormalMode = soundMode == RingerModeStatus.normal;
      _isSpeakerVolumeOn = speakerVolume > 0;
      _isBluetoothConnected = bluetoothConnection;
      _hasNotificationPermission = notificationPermission;
      _hasBatteryOptimizationPermission = batteryOptimizationPermission;
      _isCheckComplete = true;
    });
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Provider.of<TimerProvider>(context, listen: false).setOnTimerScreen(false);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Timer')),
        body: Consumer2<TimerProvider, BrightnessProvider>(
          builder: (context, timerProvider, brightnessProvider, child) {
            return Stack(
              children: [
                Column(
                  children: [
                    if (_isNormalMode)
                      WarningMessage(
                        message: "Your device is not in silent or vibrate mode. You may disturb the performance.",
                        buttonMessage: "Check Again",
                        onCheckAgain: () => _checkDeviceStatus(),
                      ),
                    if (_isSpeakerVolumeOn && !_isBluetoothConnected)
                      WarningMessage(
                        message: "Speaker volume is on. Please turn it off or connect headphones.",
                        buttonMessage: "Check Again",
                        onCheckAgain: () => _checkDeviceStatus(),
                      ),
                    if (_isCheckComplete && (!_hasNotificationPermission || !_hasBatteryOptimizationPermission))
                      WarningMessage(
                        message: "The app needs notification and battery optimization permissions to function properly. Please grant these permissions in the app settings.",
                        buttonMessage: "Settings",
                        onCheckAgain: () => _showSettingsDialog(context),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: timerProvider.playTimes.length,
                        itemBuilder: (context, index) {
                          final time = timerProvider.playTimes[index];
                          final isPast = timerProvider.currentTime >= time;
                          final isCurrent = index == timerProvider.currentPlayTimeIndex;

                          return TimelineItem(
                            time: time,
                            isPast: isPast,
                            isCurrent: isCurrent,
                          );
                        },
                      ),
                    ),
                    TimerControls(timerProvider: timerProvider),
                    BrightnessSlider(brightnessProvider: brightnessProvider),
                  ],
                ),
                if (timerProvider.showGlowingBorders && (timerProvider.isWarning || timerProvider.isPlayTime))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: GlowingBorders(
                        color: timerProvider.isWarning ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

}


