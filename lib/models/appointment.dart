class Appointment {
  String id;
  String clientId;
  String clientName;
  DateTime dateTime;
  String description;
  double value;
  String status;
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
