// lib/widgets/shake_detector.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:provider/provider.dart';
import '../providers/brightness_provider.dart';

class ShakeDetector extends StatefulWidget {
  final Widget child;

  const ShakeDetector({Key? key, required this.child}) : super(key: key);

  @override
  _ShakeDetectorState createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  static const double _shakeThreshold = 2.7; // Lowered threshold
  static const Duration _cooldownDuration = Duration(milliseconds: 500); // Shorter cooldown

  DateTime? _lastShake;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen(_onAccelerometerEvent);
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final double gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) / 9.80665;

    if (gForce > _shakeThreshold) {
      final now = DateTime.now();
      if (_lastShake == null || now.difference(_lastShake!) > _cooldownDuration) {
        _lastShake = now;
        print('Shake detected! G-force: $gForce'); // Debug print
        Provider.of<BrightnessProvider>(context, listen: false).resetBrightness();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
