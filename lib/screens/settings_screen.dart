import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import 'package:numberpicker/numberpicker.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Consumer<TimerProvider>(
        builder: (context, timerProvider, child) {
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
}
