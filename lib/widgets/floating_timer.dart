// lib/widgets/floating_timer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
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

        final currentTime = timerProvider.currentTime;
        final nextPlayTime = timerProvider.nextPlayTime;

        return Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: GestureDetector(
            onTap: onTap,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 12),
                        Text(
                          formatHms(currentTime),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (nextPlayTime != null)
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 12),
                          Text(
                            formatHms(nextPlayTime),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
