import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:volume_control/volume_control.dart';

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
      FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      return devices.any((device) => device.isConnected);
    } catch (e) {
      print("Failed to check Bluetooth connection: $e");
      return false;
    }
  }
}
