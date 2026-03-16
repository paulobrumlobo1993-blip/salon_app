import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/appointment.dart';
import '../models/client.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }
    return user.uid;
  }

  // ── Clients ──────────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> get _clientsRef =>
      _db.collection('clients');

  static Future<void> saveClient(Client client) async {
    await _clientsRef.doc(client.id).set({
      'id': client.id,
      'ownerId': _uid,
      'name': client.name,
      'phone': client.phone,
      'email': client.email,
      'notes': client.notes,
      'createdAt': Timestamp.fromDate(client.createdAt),
    });
  }

  static Future<void> deleteClient(String id) async {
    await _clientsRef.doc(id).delete();
  }

  static Stream<List<Client>> clientsStream() {
    return _clientsRef.where('ownerId', isEqualTo: _uid).snapshots().map((
      snapshot,
    ) {
      final clients = snapshot.docs.map((doc) {
        final data = doc.data();
        return Client(
          id: data['id'] as String,
          name: data['name'] as String,
          phone: data['phone'] as String,
          email: data['email'] as String?,
          notes: data['notes'] as String?,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      clients.sort((a, b) => a.name.compareTo(b.name));
      return clients;
    });
  }

  static Future<Client?> getClient(String id) async {
    final doc = await _clientsRef.doc(id).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    if (data['ownerId'] != _uid) return null;

    return Client(
      id: data['id'] as String,
      name: data['name'] as String,
      phone: data['phone'] as String,
      email: data['email'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // ── Appointments ─────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _db.collection('appointments');

  static Future<void> saveAppointment(Appointment appointment) async {
    await _appointmentsRef.doc(appointment.id).set({
      'id': appointment.id,
      'ownerId': _uid,
      'clientId': appointment.clientId,
      'clientName': appointment.clientName,
      'dateTime': Timestamp.fromDate(appointment.dateTime),
      'description': appointment.description,
      'value': appointment.value,
      'status': appointment.status,
      'createdAt': Timestamp.fromDate(appointment.createdAt),
    });
  }

  static Future<void> deleteAppointment(String id) async {
    await _appointmentsRef.doc(id).delete();
  }

  static Stream<List<Appointment>> appointmentsStream() {
    return _appointmentsRef.where('ownerId', isEqualTo: _uid).snapshots().map((
      snapshot,
    ) {
      final appointments = snapshot.docs.map((doc) {
        final data = doc.data();
        return Appointment(
          id: data['id'] as String,
          clientId: data['clientId'] as String,
          clientName: data['clientName'] as String,
          dateTime: (data['dateTime'] as Timestamp).toDate(),
          description: data['description'] as String,
          value: (data['value'] as num).toDouble(),
          status: data['status'] as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    });
  }

  static Future<List<Appointment>> getAppointmentsByDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final snapshot =
        await _appointmentsRef.where('ownerId', isEqualTo: _uid).get();

    final appointments = snapshot.docs.map((doc) {
      final data = doc.data();
      return Appointment(
        id: data['id'] as String,
        clientId: data['clientId'] as String,
        clientName: data['clientName'] as String,
        dateTime: (data['dateTime'] as Timestamp).toDate(),
        description: data['description'] as String,
        value: (data['value'] as num).toDouble(),
        status: data['status'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).where((a) {
      return a.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
          a.dateTime.isBefore(end);
    }).toList();

    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return appointments;
  }

  static Future<List<Appointment>> getAppointmentsByMonth(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end =
        month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);

    final snapshot =
        await _appointmentsRef.where('ownerId', isEqualTo: _uid).get();

    final appointments = snapshot.docs.map((doc) {
      final data = doc.data();
      return Appointment(
        id: data['id'] as String,
        clientId: data['clientId'] as String,
        clientName: data['clientName'] as String,
        dateTime: (data['dateTime'] as Timestamp).toDate(),
        description: data['description'] as String,
        value: (data['value'] as num).toDouble(),
        status: data['status'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).where((a) {
      return a.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
          a.dateTime.isBefore(end);
    }).toList();

    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return appointments;
  }

  static Future<List<Appointment>> getAllAppointments() async {
    final snapshot =
        await _appointmentsRef.where('ownerId', isEqualTo: _uid).get();

    final appointments = snapshot.docs.map((doc) {
      final data = doc.data();
      return Appointment(
        id: data['id'] as String,
        clientId: data['clientId'] as String,
        clientName: data['clientName'] as String,
        dateTime: (data['dateTime'] as Timestamp).toDate(),
        description: data['description'] as String,
        value: (data['value'] as num).toDouble(),
        status: data['status'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();

    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return appointments;
  }
}
