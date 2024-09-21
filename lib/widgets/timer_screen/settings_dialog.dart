import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../services/permission_service.dart';
class SettingsDialog extends StatelessWidget {
  final PermissionService permissionService = PermissionService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Grant Permissions'),
      content: Text('Please grant the required permissions in the settings.'),
      actions: <Widget>[
        TextButton(
          child: Text('Open Notification Settings'),
          onPressed: () {
            Navigator.of(context).pop();
            permissionService.openNotificationSettings();
          },
        ),
        if (Platform.isAndroid)
          TextButton(
            child: Text('Open Battery Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              _openBatteryOptimizationSettings(context);
            },
          ),
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _openBatteryOptimizationSettings(BuildContext context) async {
    try {
      await permissionService.openBatteryOptimizationSettings();

      // Show a dialog to guide the user after a short delay
      await Future.delayed(Duration(seconds: 1));
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Battery Optimization'),
              content: Text('Please find and disable "Pause app activity if unused" or any similar battery optimization setting for this app.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // If it fails, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open battery settings. Please open app settings manually and disable battery optimization.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}
