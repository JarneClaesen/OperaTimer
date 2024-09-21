import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import '../providers/timer_provider.dart';
import '../providers/brightness_provider.dart';
import '../widgets/glowing_borders.dart';
import '../widgets/timer_screen/timeline_item.dart';
import '../widgets/timer_screen/timer_controls.dart';
import '../widgets/timer_screen/brightness_slider.dart';
import '../widgets/timer_screen/warning_message.dart';
import '../services/device_check_service.dart';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final DeviceCheckService _deviceCheckService = DeviceCheckService();
  bool _isNormalMode = false;
  bool _isSpeakerVolumeOn = false;
  bool _isBluetoothConnected = false;

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

    setState(() {
      _isNormalMode = soundMode == RingerModeStatus.normal;
      _isSpeakerVolumeOn = speakerVolume > 0;
      _isBluetoothConnected = bluetoothConnection;
    });
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
                        onCheckAgain: () => _checkDeviceStatus(),
                      ),
                    if (_isSpeakerVolumeOn && !_isBluetoothConnected)
                      WarningMessage(
                        message: "Speaker volume is on. Please turn it off or connect headphones.",
                        onCheckAgain: () => _checkDeviceStatus(),
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
