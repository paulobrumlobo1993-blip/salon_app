import 'package:hive/hive.dart';

part 'appointment.g.dart';

@HiveType(typeId: 1)
class Appointment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String clientId;

  @HiveField(2)
  String clientName;

  @HiveField(3)
  DateTime dateTime;

  @HiveField(4)
  String description;

  @HiveField(5)
  double value;

  @HiveField(6)
  String status;

  @HiveField(7)
  DateTime createdAt;

  Appointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.dateTime,
    required this.description,
    required this.value,
    this.status = 'scheduled',
    required this.createdAt,
  });
}
