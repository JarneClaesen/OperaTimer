import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                onTap: () => _showNumberPicker(context, timerProvider, true),
              ),
              ListTile(
                title: Text('Play Duration (seconds)'),
                trailing: Text(timerProvider.playDuration.toString()),
                onTap: () => _showNumberPicker(context, timerProvider, false),
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
              ListTile(
                title: Text('App Color'),
                trailing: CircleAvatar(
                  backgroundColor: themeProvider.currentColor,
                ),
                onTap: () => _showColorPicker(context, themeProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNumberPicker(BuildContext context, TimerProvider timerProvider, bool isWarningTime) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int currentValue = isWarningTime ? timerProvider.warningTime : timerProvider.playDuration;
        return AlertDialog(
          title: Text(isWarningTime ? 'Set Warning Time' : 'Set Play Duration'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return NumberPicker(
                value: currentValue,
                minValue: 1,
                maxValue: 300,
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
                if (isWarningTime) {
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
                        ? Icon(Icons.check, color: Colors.white)
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
