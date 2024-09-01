import 'package:flutter/services.dart';

class NotificationTimer {
  static const MethodChannel _channel = MethodChannel('notification_timer');

  static Future<void> initialize() async {
    await _channel.invokeMethod('initialize');
  }

  static Future<void> play(int timeMillis) async {
    await _channel.invokeMethod('play', {'timeMillis': timeMillis});
  }

  static Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  static Future<void> terminate() async {
    await _channel.invokeMethod('terminate');
  }
}
