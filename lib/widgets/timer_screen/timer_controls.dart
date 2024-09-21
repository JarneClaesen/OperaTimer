import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_provider.dart';
import 'animated_play_pause_container.dart';
import 'jump_button.dart';

class TimerControls extends StatelessWidget {
  final TimerProvider timerProvider;

  const TimerControls({Key? key, required this.timerProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              if (timerProvider.isRunning || timerProvider.currentTime != 0)
                Positioned(
                  top: 15,
                  left: timerProvider.showJumpButtons ? 15 : 75,
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
              if (timerProvider.showJumpButtons) ...[
                Positioned(
                  left: 80,
                  top: 15,
                  child: JumpButton(
                    icon: Icons.fast_rewind_rounded,
                    onPressed: timerProvider.debouncedJumpBackward,
                  ),
                ),
                Positioned(
                  right: 80,
                  top: 15,
                  child: JumpButton(
                    icon: Icons.fast_forward_rounded,
                    onPressed: timerProvider.debouncedJumpForward,
                  ),
                ),
              ],
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