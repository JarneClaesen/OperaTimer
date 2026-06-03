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
          SizedBox(
            height: 80,
            child: Row(
              children: [
                // Left slot for the reset button. Mirrored by an equal-width
                // spacer on the right so the play/jump cluster stays centered.
                SizedBox(
                  width: 56,
                  child: (timerProvider.isRunning || timerProvider.currentTime != 0)
                      ? Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
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
                        )
                      : null,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (timerProvider.showJumpButtons) ...[
                        JumpButton(
                          icon: Icons.fast_rewind_rounded,
                          onPressed: timerProvider.debouncedJumpBackward,
                          timerProvider: timerProvider,
                        ),
                        SizedBox(width: 16),
                      ],
                      AnimatedPlayPauseContainer(
                        isRunning: timerProvider.isRunning,
                        onPressed: () {
                          if (timerProvider.isRunning) {
                            timerProvider.pauseTimer();
                          } else {
                            timerProvider.startTimer();
                          }
                        },
                      ),
                      if (timerProvider.showJumpButtons) ...[
                        SizedBox(width: 16),
                        JumpButton(
                          icon: Icons.fast_forward_rounded,
                          onPressed: timerProvider.debouncedJumpForward,
                          timerProvider: timerProvider,
                        ),
                      ],
                    ],
                  ),
                ),
                // Right spacer mirrors the reset slot to keep the cluster centered.
                const SizedBox(width: 56),
              ],
            ),
          ),
          if (timerProvider.showJumpButtons)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Jump: ${timerProvider.jumpSeconds}s",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}