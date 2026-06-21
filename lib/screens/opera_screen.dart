// lib/screens/opera_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/opera.dart';
import '../models/setlist.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/screen_with_floating_timer.dart';
import 'timer_screen.dart';

class OperaScreen extends StatelessWidget {
  final Opera opera;

  OperaScreen({required this.opera});

  @override
  Widget build(BuildContext context) {
    return ScreenWithFloatingTimer(
      child: Scaffold(
        body: Consumer<TimerProvider>(
          builder: (context, timerProvider, child) {
            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  pinned: true,
                  title: Text(opera.name),
                ),
                if (opera.parts.isEmpty)
                  const _EmptyState()
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
                    sliver: SliverList.builder(
                      itemCount: opera.parts.length,
                      itemBuilder: (context, index) {
                        final part = opera.parts[index];
                        final isPlaying =
                            timerProvider.currentOperaName == opera.name &&
                                listEquals(
                                    timerProvider.playTimes, part.playTimes);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PartCard(
                            part: part,
                            isPlaying: isPlaying,
                            onTap: () {
                              timerProvider.setCurrentOpera(
                                  opera.name, part.playTimes);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TimerScreen()),
                              );
                            },
                          ),
                        );
                      },
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

class _PartCard extends StatelessWidget {
  final Setlist part;
  final bool isPlaying;
  final VoidCallback onTap;

  const _PartCard({
    required this.part,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final Color container =
        isPlaying ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final Color onContainer =
        isPlaying ? scheme.onPrimaryContainer : scheme.onSurface;
    final int count = part.playTimes.length;

    return Material(
      color: container,
      shape: AppTheme.shapeLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingBadge(isPlaying: isPlaying),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.partName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge?.copyWith(color: onContainer),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'play time' : 'play times'}'
                      '${isPlaying ? ' · Now playing' : ''}',
                      style: text.bodyMedium?.copyWith(
                          color: onContainer.withValues(alpha: 0.75)),
                    ),
                    if (part.playTimes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: part.playTimes.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: onContainer.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXs),
                            ),
                            child: Text(
                              formatHms(t),
                              style: text.labelMedium?.copyWith(
                                color: onContainer.withValues(alpha: 0.9),
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: onContainer.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingBadge extends StatelessWidget {
  final bool isPlaying;
  const _LeadingBadge({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg = isPlaying ? scheme.primary : scheme.surfaceContainerHighest;
    final Color fg = isPlaying ? scheme.onPrimary : scheme.onSurfaceVariant;
    final IconData icon =
        isPlaying ? Icons.graphic_eq_rounded : Icons.queue_music_rounded;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: fg),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Icon(Icons.queue_music_rounded,
                  size: 48, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: 24),
            Text('No parts yet', style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Edit this opera to add parts and give them play times.',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
