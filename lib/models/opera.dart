import 'package:hive/hive.dart';
import 'setlist.dart';

part 'opera.g.dart';

@HiveType(typeId: 0)
class Opera extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<Setlist> parts;

  Opera({required this.name, required this.parts});
}
