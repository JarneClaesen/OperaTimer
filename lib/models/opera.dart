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

  Map<String, dynamic> toJson() => {
    'name': name,
    'parts': parts.map((part) => part.toJson()).toList(),
  };

  factory Opera.fromJson(Map<String, dynamic> json) => Opera(
    name: json['name'],
    parts: (json['parts'] as List).map((part) => Setlist.fromJson(part)).toList(),
  );
}