import 'package:hive/hive.dart';

part 'client.g.dart';

@HiveType(typeId: 0)
class Client extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.notes,
    required this.createdAt,
  });
}
