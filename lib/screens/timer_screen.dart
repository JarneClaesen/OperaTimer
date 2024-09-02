// lib/screens/timer_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import '../providers/timer_provider.dart';
import '../providers/brightness_provider.dart';
import '../widgets/glowing_borders.dart';
import '../widgets/timer_screen/animated_play_pause_container.dart';
import '../widgets/timer_screen/jump_button.dart';
import '../widgets/timer_screen/play_pause_button.dart';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  bool _isNormalMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TimerProvider>(context, listen: false).setOnTimerScreen(true);
      _checkSoundMode();
    });
  }

  @override
  void dispose() {
    Provider.of<TimerProvider>(context, listen: false).setOnTimerScreen(false);
    super.dispose();
  }

  Future<void> _checkSoundMode() async {
    try {
      final ringerStatus = await SoundMode.ringerModeStatus;
      setState(() {
        _isNormalMode = ringerStatus == RingerModeStatus.normal;
      });
    } catch (e) {
      print("Failed to get ringer status: $e");
    }
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
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.onTertiaryContainer),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your device is not in silent or vibrate mode. You may disturb the performance.',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onTertiaryContainer.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      'Check Again',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
                                    ),
                                    onPressed: _checkSoundMode,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

class TimelineItem extends StatelessWidget {
  final int time;
  final bool isPast;
  final bool isCurrent;

  const TimelineItem({
    Key? key,
    required this.time,
    required this.isPast,
    required this.isCurrent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hours = time ~/ 3600;
    final minutes = (time % 3600) ~/ 60;
    final seconds = time % 60;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPast ? Colors.green : (isCurrent ? Colors.orange : Colors.grey),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPast ? Colors.green.withOpacity(0.1) : (isCurrent ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isPast ? Colors.green : (isCurrent ? Colors.orange : Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimerControls extends StatelessWidget {
  final TimerProvider timerProvider;

  const TimerControls({Key? key, required this.timerProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ensures the Container takes full width of its parent
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<TimerProvider>(
            builder: (context, timerProvider, child) {
              return Text(
                '${timerProvider.currentTime ~/ 3600}:${(timerProvider.currentTime % 3600 ~/ 60).toString().padLeft(2, '0')}:${(timerProvider.currentTime % 60).toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 48),
              );
            },
          ),
          SizedBox(height: 20),
          Stack(
            children: [
              // Reset button positioned to the far left
              if (timerProvider.isRunning || timerProvider.currentTime != 0)
                Positioned(
                  top: 15,
                  left: timerProvider.showJumpButtons ? 0 : 60,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        size: 30,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Reset Timer'),
                              content: Text('Are you sure you want to reset the timer?'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Reset'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    timerProvider.stopTimer();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              // Rewind button next to reset
              if (timerProvider.showJumpButtons) ...[
                // Rewind button
                Positioned(
                  left: 80,
                  top: 15,
                  child: JumpButton(
                    icon: Icons.fast_rewind_rounded,
                    onPressed: timerProvider.debouncedJumpBackward,
                  ),
                ),
                // Forward button
                Positioned(
                  right: 80,
                  top: 15,
                  child: JumpButton(
                    icon: Icons.fast_forward_rounded,
                    onPressed: timerProvider.debouncedJumpForward,
                  ),
                ),
              ],
              // Play/Pause button in the center
              Align(
                alignment: Alignment.center,
                child: AnimatedPlayPauseContainer(
                  isRunning: timerProvider.isRunning,
                  onPressed: () {
                    if (timerProvider.isRunning) {
                      timerProvider.pauseTimer();
                    } else {
                      timerProvider.startTimer();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




class BrightnessSlider extends StatelessWidget {
  final BrightnessProvider brightnessProvider;

  const BrightnessSlider({Key? key, required this.brightnessProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20, top: 4, right: 20, bottom: 40),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          Icon(Icons.brightness_6_rounded),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.0, // Make the track thinner
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0), // Make the thumb smaller
                overlayShape: RoundSliderOverlayShape(overlayRadius: 26.0), // Adjust the overlay size
              ),
              child: Slider(
                value: brightnessProvider.brightness,
                onChanged: (value) {
                  brightnessProvider.setBrightness(value);
                },
                min: 0.0,
                max: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

