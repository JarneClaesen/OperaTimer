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
import 'package:numberpicker/numberpicker.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Consumer2<TimerProvider, ThemeProvider>(
        builder: (context, timerProvider, themeProvider, child) {
          return ListView(
            children: [
              ListTile(
                title: Text('Warning Time (seconds)'),
                trailing: Text(timerProvider.warningTime.toString()),
                onTap: () => _showNumberPicker(context, timerProvider, isWarningTime: true),
              ),
              ListTile(
                title: Text('Play Duration (seconds)'),
                trailing: Text(timerProvider.playDuration.toString()),
                onTap: () => _showNumberPicker(context, timerProvider, isWarningTime: false),
              ),
              SwitchListTile(
                title: Text('Show Jump Buttons'),
                value: timerProvider.showJumpButtons,
                onChanged: (bool value) {
                  timerProvider.setShowJumpButtons(value);
                },
              ),
              ListTile(
                title: Text('Jump Seconds'),
                trailing: Text(timerProvider.jumpSeconds.toString()),
                onTap: timerProvider.showJumpButtons
                    ? () => _showNumberPicker(context, timerProvider, isJumpSeconds: true)
                    : null,
                enabled: timerProvider.showJumpButtons,
                textColor: timerProvider.showJumpButtons
                    ? null
                    : Theme.of(context).disabledColor,
                iconColor: timerProvider.showJumpButtons
                    ? null
                    : Theme.of(context).disabledColor,
              ),
              SwitchListTile(
                title: Text('Send Warning Notifications'),
                value: timerProvider.sendWarningNotifications,
                onChanged: (bool value) {
                  timerProvider.setSendWarningNotifications(value);
                },
              ),
              SwitchListTile(
                title: Text('Send Play Time Notifications'),
                value: timerProvider.sendPlayTimeNotifications,
                onChanged: (bool value) {
                  timerProvider.setSendPlayTimeNotifications(value);
                },
              ),
              SwitchListTile(
                title: Text('Show Glowing Borders'),
                value: timerProvider.showGlowingBorders,
                onChanged: (bool value) {
                  timerProvider.setShowGlowingBorders(value);
                },
              ),
              ListTile(
                title: Text('App Color'),
                trailing: CircleAvatar(
                  backgroundColor: themeProvider.currentColor,
                ),
                onTap: () => _showColorPicker(context, themeProvider),
              ),
              Divider(),

              ListTile(
                title: Text('Export Opera Data'),
                leading: Icon(Icons.upload_rounded),
                onTap: () => _exportData(context),
              ),
              ListTile(
                title: Text('Import Opera Data'),
                leading: Icon(Icons.download_rounded),
                onTap: () => _importData(context),
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
      final result = await FilePicker.platform.getDirectoryPath();
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
          title: Text('Choose App Color'),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: themeProvider.predefinedColors.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    themeProvider.setColor(themeProvider.predefinedColors[index]);
                    Navigator.of(context).pop();
                  },
                  child: CircleAvatar(
                    backgroundColor: themeProvider.predefinedColors[index],
                    child: themeProvider.currentColor == themeProvider.predefinedColors[index]
                        ? Icon(Icons.check_rounded, color: Colors.white)
                        : null,
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
