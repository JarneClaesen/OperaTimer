// lib/widgets/floating_timer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';

class FloatingTimer extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingTimer({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        if (timerProvider.isOnTimerScreen) {
          return SizedBox.shrink();
        }

        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        final currentTime = timerProvider.currentTime;
        final nextPlayTime = timerProvider.nextPlayTime;

        return Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Material(
            color: scheme.secondaryContainer,
            shape: AppTheme.shapeLg,
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: scheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatHms(currentTime),
                          style: text.titleLarge?.copyWith(
                            color: scheme.onSecondaryContainer,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    if (nextPlayTime != null)
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 20,
                            color: scheme.onSecondaryContainer
                                .withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatHms(nextPlayTime),
                            style: text.titleMedium?.copyWith(
                              color: scheme.onSecondaryContainer
                                  .withValues(alpha: 0.75),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
