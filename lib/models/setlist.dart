import 'package:hive/hive.dart';

part 'setlist.g.dart';

@HiveType(typeId: 1)
class Setlist extends HiveObject {
  @HiveField(0)
  String partName;

  @HiveField(1)
  List<int> playTimes;

  Setlist({required this.partName, required this.playTimes});
}
