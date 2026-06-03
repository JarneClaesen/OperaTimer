import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';

// Custom enum to replace the one from sound_mode
enum RingerModeStatus { normal, silent, vibrate, unknown }

class DeviceCheckService {
  // Use the singleton instance of VolumeController
  final VolumeController _volumeController = VolumeController.instance;

  // Replaces the unmaintained flutter_dnd plugin (which used Flutter's removed
  // v1 embedding). Mirrors NotificationManager.getCurrentInterruptionFilter().
  static const MethodChannel _dndChannel = MethodChannel('orchestra_timer/dnd');

  Future<int?> _getCurrentInterruptionFilter() async {
    try {
      return await _dndChannel.invokeMethod<int>('getCurrentInterruptionFilter');
    } catch (e) {
      logDebug("Failed to get DND interruption filter: $e");
      return null;
    }
  }

  Future<RingerModeStatus> checkSoundMode() async {
    try {
      // Handle different platforms
      if (Platform.isAndroid) {
        // Check if Do Not Disturb is enabled
        final filter = await _getCurrentInterruptionFilter();

        // If DND is enabled, consider it as silent mode
        if (filter != null && filter > 0) {
          return RingerModeStatus.silent;
        }

        // Check volume level to determine if we're in vibrate mode
        // Correct way: use the instance method
        final volume = await _volumeController.getVolume();
        if (volume < 0.01) { // Very low or zero volume can be considered vibrate mode
          return RingerModeStatus.vibrate;
        } else {
          return RingerModeStatus.normal;
        }
      } else if (Platform.isIOS) {
        // On iOS, we can only check Do Not Disturb mode
        final filter = await _getCurrentInterruptionFilter();
        return (filter != null && filter > 0)
            ? RingerModeStatus.silent
            : RingerModeStatus.normal;
      } else {
        // For Windows or other platforms where we can't determine accurately
        return RingerModeStatus.unknown;
      }
    } catch (e) {
      logDebug("Failed to get ringer status: $e");
      return RingerModeStatus.unknown;
    }
  }

  Future<double> checkSpeakerVolume() async {
    try {
      return await _volumeController.getVolume();
    } catch (e) {
      logDebug("Failed to get speaker volume: $e");
      return 0.0;
    }
  }

  // A2DP (Advanced Audio Distribution Profile) service UUID — exposed by
  // audio sinks such as headphones and speakers.
  static final Guid _a2dpServiceUuid =
      Guid('0000110A-0000-1000-8000-00805F9B34FB');

  Future<bool> checkBluetoothConnection() async {
    try {
      // Check permissions first
      if (!await requestBluetoothPermission()) {
        return false;
      }

      // Check if Bluetooth is supported and enabled
      if (await FlutterBluePlus.isSupported == false) {
        logDebug("Bluetooth is not supported on this device");
        return false;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        logDebug("Bluetooth is not enabled");
        return false;
      }

      // Query devices already connected to the system (by any app or the OS).
      // This is near-instant and avoids the previous multi-second active scan.
      // The A2DP service filter is honoured on iOS (required for privacy) and
      // ignored on Android, where we fall back to a device-name heuristic.
      final connectedDevices =
          await FlutterBluePlus.systemDevices([_a2dpServiceUuid]);

      if (Platform.isIOS) {
        // iOS only returns devices exposing the requested A2DP service, so any
        // result is already an audio device.
        return connectedDevices.isNotEmpty;
      }
      return connectedDevices.any(_isLikelyAudioDevice);
    } catch (e) {
      logDebug("Bluetooth connection check error: $e");
      return false;
    }
  }

  // Helper method to check if device is likely an audio device
  bool _isLikelyAudioDevice(BluetoothDevice device) {
    final name = device.platformName.toLowerCase();
    return name.contains('headphone') ||
        name.contains('earphone') ||
        name.contains('speaker') ||
        name.contains('audio') ||
        name.contains('sound');
  }

  // Performs a deeper check by connecting and inspecting the device's GATT
  // services. Requires an active connection, so it is only suitable when the
  // device is already connected to this app.
  Future<bool> isAudioDevice(BluetoothDevice device) async {
    if (_isLikelyAudioDevice(device)) {
      return true;
    }

    // Check services
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        // Check for A2DP (Advanced Audio Distribution Profile) or HSP (Headset Profile)
        if (service.uuid == _a2dpServiceUuid || // A2DP
            service.uuid == Guid('00001108-0000-1000-8000-00805F9B34FB')) { // HSP
          return true;
        }
      }
    } catch (e) {
      logDebug("Failed to discover services: $e");
    }

    return false;
  }

  Future<bool> requestBluetoothPermission() async {
    if (await Permission.bluetooth.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      return true;
    }
    return false;
  }
}
