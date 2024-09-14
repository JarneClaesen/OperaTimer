import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider with ChangeNotifier {
  static const String _colorKey = 'app_color';
  static const String _boxName = 'theme_box';

  final List<Color> _predefinedColors = [
    Color(0xFF800020), // Burgundy (original color)
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Color(0xFF1A237E), // Indigo[900]
    Colors.indigo,
    Color(0xFF0D47A1), // Blue[900]
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Color(0xFF006064), // Cyan[900]
    Colors.teal,
    Color(0xFF1B5E20), // Green[900]
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  Color _currentColor;
  late Box<int> _box;

  ThemeProvider() : _currentColor = Color(0xFF800020) {
    _initHive();
  }

  List<Color> get predefinedColors => _predefinedColors;

  Color get currentColor => _currentColor;

  Future<void> _initHive() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<int>(_boxName);
    await _loadSavedColor();
  }

  Future<void> setColor(Color color) async {
    if (_currentColor != color) {
      _currentColor = color;
      notifyListeners();
      await _saveColor();
    }
  }

  Future<void> _loadSavedColor() async {
    final colorValue = _box.get(_colorKey);
    if (colorValue != null) {
      _currentColor = Color(colorValue);
      notifyListeners();
    }
  }

  Future<void> _saveColor() async {
    await _box.put(_colorKey, _currentColor.value);
  }
}
