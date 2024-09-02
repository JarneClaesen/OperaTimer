import 'package:hive/hive.dart';
import '../models/opera.dart';

class HiveHelper {
  static Box<Opera>? _operasBox;

  static Future<Box<Opera>> getOperasBox() async {
    if (_operasBox == null || !_operasBox!.isOpen) {
      _operasBox = await Hive.openBox<Opera>('operas');
    }
    return _operasBox!;
  }

  static Future<void> closeBox() async {
    if (_operasBox != null && _operasBox!.isOpen) {
      await _operasBox!.close();
      _operasBox = null;
    }
  }
}
