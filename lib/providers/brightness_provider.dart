// lib/providers/brightness_provider.dart

import 'package:flutter/foundation.dart';

class BrightnessProvider with ChangeNotifier {
  double _brightness = 1.0;

  double get brightness => _brightness;

  void setBrightness(double value) {
    if (_brightness != value) {
      _brightness = value;
      notifyListeners();
    }
  }

  void resetBrightness() {
    print('Resetting brightness to 1.0'); // Debug print
    setBrightness(1.0);
  }
}
