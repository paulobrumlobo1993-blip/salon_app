class Client {
  String id;
  String name;
  String phone;
  String? email;
  String? notes;
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
