import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:permission_handler/permission_handler.dart';

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
      print("Failed to get DND interruption filter: $e");
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
      print("Failed to get ringer status: $e");
      return RingerModeStatus.unknown;
    }
  }

  Future<double> checkSpeakerVolume() async {
    try {
      return await _volumeController.getVolume();
    } catch (e) {
      print("Failed to get speaker volume: $e");
      return 0.0;
    }
  }

  Future<bool> checkBluetoothConnection() async {
    try {
      // Check permissions first
      if (!await requestBluetoothPermission()) {
        return false;
      }

      // Check if Bluetooth is supported and enabled
      if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth is not supported on this device");
        return false;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print("Bluetooth is not enabled");
        return false;
      }

      // Start scanning with timeout
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

      // Use a completer to handle the async scan results
      final completer = Completer<bool>();
      StreamSubscription? subscription;

      subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          if (_isLikelyAudioDevice(result.device)) {
            subscription?.cancel();
            completer.complete(true);
            return;
          }
        }
      });

      // Set timeout
      Timer(Duration(seconds: 6), () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete(false);
        }
      });

      return await completer.future;
    } catch (e) {
      print("Bluetooth scan error: $e");
      return false;
    } finally {
      try {
        await FlutterBluePlus.stopScan();
      } catch (e) {
        // Ignore errors when stopping scan
      }
    }
  }

  // Helper method to check if device is likely an audio device
  bool _isLikelyAudioDevice(BluetoothDevice device) {
    final name = device.name.toLowerCase();
    return name.contains('headphone') ||
        name.contains('earphone') ||
        name.contains('speaker') ||
        name.contains('audio') ||
        name.contains('sound');
  }

  Future<bool> isAudioDevice(BluetoothDevice device) async {
    // Check device name
    if (device.name.toLowerCase().contains('headphone') ||
        device.name.toLowerCase().contains('earphone') ||
        device.name.toLowerCase().contains('speaker')) {
      return true;
    }

    // Check services
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        // Check for A2DP (Advanced Audio Distribution Profile) or HSP (Headset Profile)
        if (service.uuid == Guid('0000110A-0000-1000-8000-00805F9B34FB') || // A2DP
            service.uuid == Guid('00001108-0000-1000-8000-00805F9B34FB')) { // HSP
          return true;
        }
      }
    } catch (e) {
      print("Failed to discover services: $e");
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
