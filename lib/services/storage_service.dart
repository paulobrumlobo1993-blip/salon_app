import 'package:hive_flutter/hive_flutter.dart';
import '../models/client.dart';
import '../models/appointment.dart';

class StorageService {
  static const String clientsBoxName = 'clients';
  static const String appointmentsBoxName = 'appointments';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(AppointmentAdapter());
    await Hive.openBox<Client>(clientsBoxName);
    await Hive.openBox<Appointment>(appointmentsBoxName);
  }

  // ── Clients ──────────────────────────────────────────────────────────────
  static Box<Client> get clientsBox => Hive.box<Client>(clientsBoxName);

  static List<Client> getAllClients() =>
      clientsBox.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  static Future<void> saveClient(Client client) async {
    await clientsBox.put(client.id, client);
  }

  static Future<void> deleteClient(String id) async {
    await clientsBox.delete(id);
  }

  static Client? getClient(String id) => clientsBox.get(id);

  // ── Appointments ──────────────────────────────────────────────────────────
  static Box<Appointment> get appointmentsBox =>
      Hive.box<Appointment>(appointmentsBoxName);

  static List<Appointment> getAllAppointments() =>
      appointmentsBox.values.toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  static Future<void> saveAppointment(Appointment appointment) async {
    await appointmentsBox.put(appointment.id, appointment);
  }

  static Future<void> deleteAppointment(String id) async {
    await appointmentsBox.delete(id);
  }

  static List<Appointment> getAppointmentsByDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return appointmentsBox.values
        .where((a) =>
            a.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            a.dateTime.isBefore(end))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  static List<Appointment> getAppointmentsByWeek(DateTime anyDayOfWeek) {
    final weekDay = anyDayOfWeek.weekday;
    final start = DateTime(
      anyDayOfWeek.year,
      anyDayOfWeek.month,
      anyDayOfWeek.day,
    ).subtract(Duration(days: weekDay - 1));
    final end = start.add(const Duration(days: 7));
    return appointmentsBox.values
        .where((a) =>
            a.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            a.dateTime.isBefore(end))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  static List<Appointment> getAppointmentsByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return appointmentsBox.values
        .where((a) =>
            a.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            a.dateTime.isBefore(end))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // ── Revenue helpers ───────────────────────────────────────────────────────
  static double revenueForDay(DateTime day) => getAppointmentsByDay(day)
      .where((a) => a.status == 'completed')
      .fold(0, (sum, a) => sum + a.value);

  static double revenueForWeek(DateTime anyDay) =>
      getAppointmentsByWeek(anyDay)
          .where((a) => a.status == 'completed')
          .fold(0, (sum, a) => sum + a.value);

  static double revenueForMonth(int year, int month) =>
      getAppointmentsByMonth(year, month)
          .where((a) => a.status == 'completed')
          .fold(0, (sum, a) => sum + a.value);
}
