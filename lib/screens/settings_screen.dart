import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/opera.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../theme/app_theme.dart';
import 'package:numberpicker/numberpicker.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<TimerProvider, ThemeProvider>(
        builder: (context, timerProvider, themeProvider, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                pinned: true,
                title: Text('Settings'),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                sliver: SliverList.list(
                  children: [
                    _SettingsSection(
                      label: 'Timing',
                      children: [
                        _SettingTile(
                          icon: Icons.timer_outlined,
                          title: 'Warning Time',
                          subtitle:
                              'How long before a play time the warning starts.',
                          trailing: _ValueLabel('${timerProvider.warningTime} s'),
                          onTap: () => _showNumberPicker(
                              context, timerProvider,
                              isWarningTime: true),
                        ),
                        _SettingTile(
                          icon: Icons.music_note_rounded,
                          title: 'Play Duration',
                          subtitle:
                              'How long the play-time state stays active.',
                          trailing:
                              _ValueLabel('${timerProvider.playDuration} s'),
                          onTap: () => _showNumberPicker(
                              context, timerProvider,
                              isWarningTime: false),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      label: 'Controls',
                      children: [
                        _SettingSwitch(
                          icon: Icons.swipe_rounded,
                          title: 'Show Jump Buttons',
                          subtitle:
                              'Add buttons to nudge the timer forward or back.',
                          value: timerProvider.showJumpButtons,
                          onChanged: (value) =>
                              timerProvider.setShowJumpButtons(value),
                        ),
                        _SettingTile(
                          icon: Icons.fast_forward_rounded,
                          title: 'Jump Seconds',
                          subtitle:
                              'How many seconds each jump button moves.',
                          trailing:
                              _ValueLabel('${timerProvider.jumpSeconds} s'),
                          enabled: timerProvider.showJumpButtons,
                          onTap: timerProvider.showJumpButtons
                              ? () => _showNumberPicker(context, timerProvider,
                                  isJumpSeconds: true)
                              : null,
                        ),
                      ],
                    ),
                    _SettingsSection(
                      label: 'Alerts',
                      children: [
                        _SettingSwitch(
                          icon: Icons.notification_important_rounded,
                          title: 'Send Warning Notifications',
                          subtitle:
                              'Get notified when a warning begins.',
                          value: timerProvider.sendWarningNotifications,
                          onChanged: (value) => timerProvider
                              .setSendWarningNotifications(value),
                        ),
                        _SettingSwitch(
                          icon: Icons.notifications_active_rounded,
                          title: 'Send Play Time Notifications',
                          subtitle:
                              'Get notified when it is time to play.',
                          value: timerProvider.sendPlayTimeNotifications,
                          onChanged: (value) => timerProvider
                              .setSendPlayTimeNotifications(value),
                        ),
                        _SettingSwitch(
                          icon: Icons.blur_on_rounded,
                          title: 'Show Glowing Borders',
                          subtitle:
                              'Glow the screen edges during warnings and play times.',
                          value: timerProvider.showGlowingBorders,
                          onChanged: (value) =>
                              timerProvider.setShowGlowingBorders(value),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      label: 'Appearance',
                      children: [
                        _SettingTile(
                          icon: Icons.palette_rounded,
                          title: 'App Color',
                          subtitle: 'Pick the accent color for the app theme.',
                          trailing: _ColorSwatch(
                              color: themeProvider.currentColor),
                          onTap: () =>
                              _showColorPicker(context, themeProvider),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      label: 'Data',
                      children: [
                        _SettingTile(
                          icon: Icons.upload_rounded,
                          title: 'Export Opera Data',
                          subtitle: 'Save all operas to a JSON file.',
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                          onTap: () => _exportData(context),
                        ),
                        _SettingTile(
                          icon: Icons.download_rounded,
                          title: 'Import Opera Data',
                          subtitle:
                              'Replace operas with data from a JSON file.',
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                          onTap: () => _importData(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final jsonString = await exportToJson();
      final result = await FilePicker.getDirectoryPath();
      if (result != null) {
        String formattedDateTime = DateFormat('ddMMyyyy_HHmmss').format(DateTime.now());
        final fileName = 'OperaTimer_$formattedDateTime.json';
        final filePath = '$result/$fileName';

        final file = File(filePath);
        await file.writeAsString(jsonString);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported to $filePath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        await importFromJson(jsonString);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data imported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing data: $e')),
      );
      print(e);
    }
  }

  Future<String> exportToJson() async {
    final box = Hive.box<Opera>('operas');
    List<Map<String, dynamic>> jsonData = box.values.map((item) => item.toJson()).toList();
    return jsonEncode(jsonData);
  }

  Future<void> importFromJson(String jsonString) async {
    final box = Hive.box<Opera>('operas');
    List<dynamic> jsonData = jsonDecode(jsonString);
    List<Opera> operas = jsonData.map((item) => Opera.fromJson(item)).toList();
    await box.clear(); // Clear existing data
    for (var opera in operas) {
      await box.add(opera);
    }
  }

  void _showNumberPicker(BuildContext context, TimerProvider timerProvider, {bool isWarningTime = false, bool isJumpSeconds = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int currentValue = isJumpSeconds ? timerProvider.jumpSeconds : (isWarningTime ? timerProvider.warningTime : timerProvider.playDuration);
        return AlertDialog(
          shape: AppTheme.shapeLg,
          icon: Icon(isJumpSeconds
              ? Icons.fast_forward_rounded
              : (isWarningTime
                  ? Icons.timer_outlined
                  : Icons.music_note_rounded)),
          title: Text(isJumpSeconds ? 'Set Jump Seconds' : (isWarningTime ? 'Set Warning Time' : 'Set Play Duration')),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return NumberPicker(
                value: currentValue,
                minValue: 1,
                maxValue: isJumpSeconds ? 60 : 300,
                onChanged: (value) => setState(() => currentValue = value),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                if (isJumpSeconds) {
                  timerProvider.setJumpSeconds(currentValue);
                } else if (isWarningTime) {
                  timerProvider.setWarningTime(currentValue);
                } else {
                  timerProvider.setPlayDuration(currentValue);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: AppTheme.shapeLg,
          icon: Icon(Icons.palette_rounded),
          title: Text('Choose App Color'),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: themeProvider.predefinedColors.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final color = themeProvider.predefinedColors[index];
                final bool selected = themeProvider.currentColor == color;
                return Material(
                  color: color,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      themeProvider.setColor(color);
                      Navigator.of(context).pop();
                    },
                    child: Center(
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// A labeled, rounded "section card" grouping related settings rows.
class _SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SettingsSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i != children.length - 1) {
        spaced.add(const SizedBox(height: 4));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              label,
              style: text.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            decoration: ShapeDecoration(
              color: scheme.surfaceContainerHigh,
              shape: AppTheme.shapeLg,
            ),
            padding: const EdgeInsets.all(8),
            child: Column(children: spaced),
          ),
        ],
      ),
    );
  }
}

/// A rounded square leading icon badge with a tonal background.
class _RowBadge extends StatelessWidget {
  final IconData icon;
  final bool enabled;

  const _RowBadge({required this.icon, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: enabled
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(
        icon,
        size: 22,
        color: enabled
            ? scheme.onSecondaryContainer
            : scheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

/// A tappable settings row backed by the section card's surface.
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      shape: AppTheme.shapeMd,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        enabled: enabled,
        shape: AppTheme.shapeMd,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: _RowBadge(icon: icon, enabled: enabled),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        textColor: enabled ? null : Theme.of(context).disabledColor,
        iconColor: enabled ? null : Theme.of(context).disabledColor,
        subtitleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: enabled
                  ? scheme.onSurfaceVariant
                  : Theme.of(context).disabledColor,
            ),
        onTap: onTap,
      ),
    );
  }
}

/// A toggle row backed by the section card's surface.
class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      shape: AppTheme.shapeMd,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      secondary: _RowBadge(icon: icon),
      title: Text(title),
      subtitle: Text(subtitle),
      subtitleTextStyle: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: scheme.onSurfaceVariant),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// A pill showing the current value on a row's trailing side.
class _ValueLabel extends StatelessWidget {
  final String text;

  const _ValueLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
      ),
      child: Text(
        text,
        style: theme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

/// The current app color shown as a bordered circle.
class _ColorSwatch extends StatelessWidget {
  final Color color;

  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
