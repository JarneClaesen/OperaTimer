import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/brightness_provider.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/glowing_borders.dart';
import '../widgets/timer_screen/settings_dialog.dart';
import '../widgets/timer_screen/timeline_item.dart';
import '../widgets/timer_screen/timer_controls.dart';
import '../widgets/timer_screen/brightness_slider.dart';
import '../widgets/timer_screen/warning_message.dart';
import '../services/device_check_service.dart';
import 'settings_screen.dart';


class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final DeviceCheckService _deviceCheckService = DeviceCheckService();
  final PermissionService _permissionService = PermissionService();
  bool _isNormalMode = false;
  bool _isSpeakerVolumeOn = false;
  bool _isBluetoothConnected = false;
  bool _hasNotificationPermission = false;
  bool _hasBatteryOptimizationPermission = false;
  bool _isCheckComplete = false;

  // Captured while the element is still active so dispose() doesn't have to do
  // an (unsafe) inherited-widget lookup on a deactivated element.
  TimerProvider? _timerProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<TimerProvider>(context, listen: false).setOnTimerScreen(true);
      _checkDeviceStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // setOnTimerScreen notifies listeners, which can't run during the unmount
    // (the widget tree is locked). Defer it to after the current frame so the
    // floating timer rebuilds cleanly once we've left this screen.
    final provider = _timerProvider;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider?.setOnTimerScreen(false);
    });
    super.dispose();
  }

  Future<void> _checkDeviceStatus() async {
    final soundMode = await _deviceCheckService.checkSoundMode();
    final speakerVolume = await _deviceCheckService.checkSpeakerVolume();
    final bluetoothConnection = await _deviceCheckService.checkBluetoothConnection();

    // Check and request permissions
    await _permissionService.requestPermissions();

    // Check permission statuses after requesting
    final notificationPermission = await Permission.notification.status.isGranted;
    final batteryOptimizationPermission = await FlutterForegroundTask.isIgnoringBatteryOptimizations;

    // The checks above include a multi-second Bluetooth lookup; bail out if the
    // user left the screen in the meantime.
    if (!mounted) return;

    setState(() {
      _isNormalMode = soundMode == RingerModeStatus.normal;
      _isSpeakerVolumeOn = speakerVolume > 0;
      _isBluetoothConnected = bluetoothConnection;
      _hasNotificationPermission = notificationPermission;
      _hasBatteryOptimizationPermission = batteryOptimizationPermission;
      _isCheckComplete = true;
    });
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        context.select<TimerProvider, String?>((p) => p.currentOperaName) ??
            'Timer';
    // `setOnTimerScreen(false)` is handled in dispose(), which runs whenever
    // this screen is popped, so no WillPopScope/PopScope is needed here.
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer2<TimerProvider, BrightnessProvider>(
        builder: (context, timerProvider, brightnessProvider, child) {
          return Stack(
            children: [
              Column(
                children: [
                  if (_isNormalMode)
                    WarningMessage(
                      message:
                          "Your device is not in silent or vibrate mode. You may disturb the performance.",
                      buttonMessage: "Check Again",
                      onCheckAgain: () => _checkDeviceStatus(),
                    ),
                  if (_isSpeakerVolumeOn && !_isBluetoothConnected)
                    WarningMessage(
                      message:
                          "Speaker volume is on. Please turn it off or connect headphones.",
                      buttonMessage: "Check Again",
                      onCheckAgain: () => _checkDeviceStatus(),
                    ),
                  if (_isCheckComplete &&
                      (!_hasNotificationPermission ||
                          !_hasBatteryOptimizationPermission))
                    WarningMessage(
                      message:
                          "The app needs notification and battery optimization permissions to function properly. Please grant these permissions in the app settings.",
                      buttonMessage: "Settings",
                      onCheckAgain: () => _showSettingsDialog(context),
                    ),
                  _NextCueHeader(timerProvider: timerProvider),
                  Expanded(
                    child: timerProvider.playTimes.isEmpty
                        ? _NoCues()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            itemCount: timerProvider.playTimes.length,
                            itemBuilder: (context, index) {
                              final time = timerProvider.playTimes[index];
                              final isPast = timerProvider.currentTime >= time;
                              final isCurrent =
                                  index == timerProvider.currentPlayTimeIndex;
                              return TimelineItem(
                                index: index + 1,
                                time: time,
                                isPast: isPast,
                                isCurrent: isCurrent,
                                isFirst: index == 0,
                                isLast:
                                    index == timerProvider.playTimes.length - 1,
                                secondsUntil: isCurrent
                                    ? time - timerProvider.currentTime
                                    : null,
                              );
                            },
                          ),
                  ),
                  TimerControls(timerProvider: timerProvider),
                  BrightnessSlider(brightnessProvider: brightnessProvider),
                ],
              ),
              if (timerProvider.showGlowingBorders &&
                  (timerProvider.isWarning || timerProvider.isPlayTime))
                Positioned.fill(
                  child: IgnorePointer(
                    child: GlowingBorders(
                      // Play-time (green) takes visual priority over an
                      // upcoming-warning (orange) when both are active.
                      color: timerProvider.isPlayTime
                          ? AppTheme.playTimeColor
                          : AppTheme.warningColor,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Expressive hero: the headline "what do I need to know right now" element.
/// Shows a live countdown to the next cue with a progress bar between the
/// previous and next cue, and tints itself amber during a warning and green
/// during a play-time window.
class _NextCueHeader extends StatelessWidget {
  final TimerProvider timerProvider;
  const _NextCueHeader({required this.timerProvider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final playTimes = timerProvider.playTimes;
    final current = timerProvider.currentTime;
    final next = timerProvider.nextPlayTime;

    // Resolve the expressive accent for the current state.
    Color bg;
    Color fg;
    Color accent;
    if (timerProvider.isPlayTime) {
      accent = AppTheme.playTimeColor;
      bg = Color.alphaBlend(accent.withValues(alpha: 0.22), scheme.surface);
      fg = scheme.onSurface;
    } else if (timerProvider.isWarning) {
      accent = AppTheme.warningColor;
      bg = Color.alphaBlend(accent.withValues(alpha: 0.22), scheme.surface);
      fg = scheme.onSurface;
    } else {
      accent = scheme.primary;
      bg = scheme.primaryContainer;
      fg = scheme.onPrimaryContainer;
    }

    String label;
    String big;
    String? sub;
    double? progress;

    if (playTimes.isEmpty) {
      label = 'NO PLAY TIMES';
      big = '--:--';
      sub = 'Add play times to this part to use the timer.';
    } else if (next == null) {
      label = 'ALL CUES COMPLETE';
      big = formatHms(current);
      sub = 'Nice work — every play time has passed.';
    } else {
      final until = next - current;
      // Previous cue (or session start) anchors the progress bar.
      int prev = 0;
      for (final t in playTimes) {
        if (t <= current) prev = t;
      }
      final span = next - prev;
      progress = span <= 0 ? 0.0 : ((current - prev) / span).clamp(0.0, 1.0);
      if (timerProvider.isPlayTime) {
        label = 'PLAY NOW';
        big = 'Now';
        sub = 'Cue at ${formatHms(next)}';
      } else {
        label = 'NEXT CUE IN';
        big = formatHms(until);
        sub = 'At ${formatHms(next)} · elapsed ${formatHms(current)}';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppTheme.brXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  timerProvider.isPlayTime
                      ? Icons.graphic_eq_rounded
                      : timerProvider.isWarning
                          ? Icons.notifications_active_rounded
                          : Icons.schedule_rounded,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: text.labelLarge
                      ?.copyWith(color: fg.withValues(alpha: 0.8), letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              big,
              style: text.displayMedium?.copyWith(
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub, style: text.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.8))),
            ],
            if (progress != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: fg.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoCues extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off_rounded,
                size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No play times', style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              'This part has no cues yet.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
