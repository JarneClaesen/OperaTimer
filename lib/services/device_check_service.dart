import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:volume_control/volume_control.dart';
import 'package:permission_handler/permission_handler.dart';


class DeviceCheckService {
  Future<RingerModeStatus> checkSoundMode() async {
    try {
      return await SoundMode.ringerModeStatus;
    } catch (e) {
      print("Failed to get ringer status: $e");
      return RingerModeStatus.unknown;
    }
  }

  Future<double> checkSpeakerVolume() async {
    try {
      return await VolumeControl.volume;
    } catch (e) {
      print("Failed to get speaker volume: $e");
      return 0.0;
    }
  }

  Future<bool> checkBluetoothConnection() async {
    try {
      bool hasPermission = await requestBluetoothPermission();
      if (!hasPermission) {
        print("Bluetooth permission not granted");
        return false;
      }

      FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      return devices.any((device) => device.isConnected);
    } catch (e) {
      print("Failed to check Bluetooth connection: $e");
      return false;
    }
  }


  Future<bool> requestBluetoothPermission() async {
    var status = await Permission.bluetooth.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      status = await Permission.bluetooth.request();
    }

    // For Android 12 and above, you also need to request BLUETOOTH_CONNECT permission
    if (status.isGranted) {
      var connectStatus = await Permission.bluetoothConnect.status;
      if (connectStatus.isDenied) {
        connectStatus = await Permission.bluetoothConnect.request();
      }
      return connectStatus.isGranted;
    }

    return status.isGranted;
  }

}
