import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';

/// One cue on the timer's vertical timeline. Past cues read green with a check,
/// the next cue glows amber with a live countdown, and upcoming cues are quiet
/// outlined nodes — the expressive "guide the eye to what matters now" idea.
class TimelineItem extends StatelessWidget {
  final int index;
  final int time;
  final bool isPast;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;
  final int? secondsUntil;

  const TimelineItem({
    Key? key,
    required this.index,
    required this.time,
    required this.isPast,
    required this.isCurrent,
    this.isFirst = false,
    this.isLast = false,
    this.secondsUntil,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final Color cardColor = isCurrent
        ? Color.alphaBlend(
            AppTheme.warningColor.withValues(alpha: 0.18), scheme.surface)
        : scheme.surfaceContainerHigh;

    String subtitle;
    Color subtitleColor;
    if (isCurrent) {
      final s = secondsUntil ?? 0;
      subtitle = s <= 0 ? 'Now' : 'in ${formatHms(s)}';
      subtitleColor = AppTheme.warningColor;
    } else if (isPast) {
      subtitle = 'Passed';
      subtitleColor = AppTheme.playTimeColor;
    } else {
      subtitle = 'Upcoming';
      subtitleColor = scheme.onSurfaceVariant;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 3,
                    color: isFirst
                        ? Colors.transparent
                        : (isPast || isCurrent)
                            ? AppTheme.playTimeColor
                            : scheme.outlineVariant,
                  ),
                ),
                _Node(
                    index: index,
                    isPast: isPast,
                    isCurrent: isCurrent,
                    scheme: scheme),
                Expanded(
                  child: Container(
                    width: 3,
                    color: isLast
                        ? Colors.transparent
                        : isPast
                            ? AppTheme.playTimeColor
                            : scheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppTheme.brMd,
                  border: isCurrent
                      ? Border.all(color: AppTheme.warningColor, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatHms(time),
                        style: text.titleLarge?.copyWith(
                          color: scheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: text.labelMedium?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  final int index;
  final bool isPast;
  final bool isCurrent;
  final ColorScheme scheme;
  const _Node({
    required this.index,
    required this.isPast,
    required this.isCurrent,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    Widget inner;
    Color bg;
    Color border;
    if (isPast) {
      bg = AppTheme.playTimeColor;
      border = AppTheme.playTimeColor;
      inner = const Icon(Icons.check_rounded, size: 16, color: Colors.white);
    } else if (isCurrent) {
      bg = AppTheme.warningColor;
      border = AppTheme.warningColor;
      inner = Text('$index',
          style: const TextStyle(
              color: AppTheme.warningOn,
              fontWeight: FontWeight.w800,
              fontSize: 13));
    } else {
      bg = scheme.surface;
      border = scheme.outlineVariant;
      inner = Text('$index',
          style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 13));
    }
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppTheme.warningColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: inner,
    );
  }
}
