// lib/providers/brightness_provider.dart

import 'package:flutter/foundation.dart';

class BrightnessProvider with ChangeNotifier {
  /// Lowest allowed brightness. The dim overlay is `black` at `1 - brightness`
  /// opacity, so a floor above 0 keeps the screen from going fully black.
  static const double minBrightness = 0.15;

  double _brightness = 1.0;

  double get brightness => _brightness;

  void setBrightness(double value) {
    final clamped = value.clamp(minBrightness, 1.0);
    if (_brightness != clamped) {
      _brightness = clamped;
      notifyListeners();
    }
  }

  void resetBrightness() {
    print('Resetting brightness to 1.0'); // Debug print
    setBrightness(1.0);
  }
}
