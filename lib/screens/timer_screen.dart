// lib/screens/timer_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/brightness_provider.dart';
import '../widgets/glowing_borders.dart';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TimerProvider>(context, listen: false).setOnTimerScreen(true);
    });
  }

  @override
  void dispose() {
    Provider.of<TimerProvider>(context, listen: false).setOnTimerScreen(false);
    super.dispose();
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
                if (timerProvider.isWarning || timerProvider.isPlayTime)
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
      padding: EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${timerProvider.currentTime ~/ 3600}:${(timerProvider.currentTime % 3600 ~/ 60).toString().padLeft(2, '0')}:${(timerProvider.currentTime % 60).toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 48),
          ),
          SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              if (timerProvider.isRunning || timerProvider.currentTime != 0)
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 150,
                  child: Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        size: 20,
                      ),
                      onPressed: () {
                        timerProvider.stopTimer();
                      },
                    ),
                  ),
                ),
              Center(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: timerProvider.isRunning ? 100 : 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: timerProvider.isRunning ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: IconButton(
                    icon: Icon(
                      timerProvider.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 40,
                    ),
                    onPressed: () {
                      if (timerProvider.isRunning) {
                        timerProvider.pauseTimer();
                      } else {
                        timerProvider.startTimer();
                      }
                    },
                  ),
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          Icon(Icons.brightness_6),
          Expanded(
            child: Slider(
              value: brightnessProvider.brightness,
              onChanged: (value) {
                brightnessProvider.setBrightness(value);
              },
              min: 0.0,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
