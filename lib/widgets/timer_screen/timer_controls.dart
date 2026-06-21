import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import '../../providers/timer_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import 'animated_play_pause_container.dart';
import 'jump_button.dart';

class TimerControls extends StatelessWidget {
  final TimerProvider timerProvider;

  const TimerControls({Key? key, required this.timerProvider}) : super(key: key);

  void _showJumpSecondsPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        int currentValue = timerProvider.jumpSeconds;
        return AlertDialog(
          shape: AppTheme.shapeLg,
          icon: const Icon(Icons.unfold_more_rounded),
          title: const Text('Jump amount'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return NumberPicker(
                value: currentValue,
                minValue: 1,
                maxValue: 60,
                onChanged: (value) => setState(() => currentValue = value),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              child: const Text('Save'),
              onPressed: () {
                timerProvider.setJumpSeconds(currentValue);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: AppTheme.shapeLg,
          icon: const Icon(Icons.replay_rounded),
          title: const Text('Reset timer?'),
          content: const Text('This returns the timer to 00:00:00.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton.tonal(
              child: const Text('Reset'),
              onPressed: () {
                Navigator.of(context).pop();
                timerProvider.stopTimer();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final showReset = timerProvider.isRunning || timerProvider.currentTime != 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle — a small expressive affordance for the control sheet.
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ELAPSED',
            style: text.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            formatHms(timerProvider.currentTime),
            style: text.displaySmall?.copyWith(
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 88,
            child: Row(
              children: [
                // Left slot for the reset button. Mirrored by an equal-width
                // spacer on the right so the play/jump cluster stays centered.
                SizedBox(
                  width: 56,
                  child: showReset
                      ? Center(
                          child: Material(
                            color: scheme.tertiaryContainer,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: IconButton(
                              icon: Icon(
                                Icons.replay_rounded,
                                color: scheme.onTertiaryContainer,
                                size: 28,
                              ),
                              onPressed: () => _confirmReset(context),
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
                          onPressed: timerProvider.jumpBackward,
                          timerProvider: timerProvider,
                        ),
                        const SizedBox(width: 16),
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
                        const SizedBox(width: 16),
                        JumpButton(
                          icon: Icons.fast_forward_rounded,
                          onPressed: timerProvider.jumpForward,
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
              padding: const EdgeInsets.only(top: 10),
              child: Material(
                color: scheme.surfaceContainerHighest,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showJumpSecondsPicker(context),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          "Jump ${timerProvider.jumpSeconds}s",
                          style: text.labelLarge
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
