import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDay = DateTime.now();
  List<Appointment> _appointments = [];
  bool _loading = true;
  Set<String> _daysWithAppointments = {};

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);

    try {
      final dayData = await FirestoreService.getAppointmentsByDay(_selectedDay);
      final monthData = await FirestoreService.getAppointmentsByMonth(
        _selectedDay.year,
        _selectedDay.month,
      );

      if (mounted) {
        setState(() {
          _appointments = dayData;
          _daysWithAppointments =
              monthData.map((a) => _dayKey(a.dateTime)).toSet();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar agendamentos.')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _CustomDatePickerDialog(initialDate: _selectedDay),
    );

    if (picked != null) {
      setState(() => _selectedDay = picked);
      await _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildDatePicker(),
          _buildDaySummary(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _appointments.length,
                        itemBuilder: (_, i) =>
                            _buildAppointmentCard(_appointments[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text('Agendar', style: GoogleFonts.lato()),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      color: AppTheme.rosePrimary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () async {
                  setState(() {
                    _selectedDay =
                        _selectedDay.subtract(const Duration(days: 1));
                  });
                  await _loadAppointments();
                },
              ),
              GestureDetector(
                onTap: _pickDate,
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEEE', 'pt_BR')
                          .format(_selectedDay)
                          .toUpperCase(),
                      style: GoogleFonts.lato(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      DateFormat("d 'de' MMMM 'de' y", 'pt_BR')
                          .format(_selectedDay),
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () async {
                  setState(() {
                    _selectedDay = _selectedDay.add(const Duration(days: 1));
                  });
                  await _loadAppointments();
                },
              ),
            ],
          ),
          _buildWeekRow(),
        ],
      ),
    );
  }

  Widget _buildWeekRow() {
    final weekDay = _selectedDay.weekday;
    final monday = _selectedDay.subtract(Duration(days: weekDay - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final d = days[i];
        final isSelected = d.day == _selectedDay.day &&
            d.month == _selectedDay.month &&
            d.year == _selectedDay.year;
        final isToday = d.day == DateTime.now().day &&
            d.month == DateTime.now().month &&
            d.year == DateTime.now().year;
        final hasAppointment = _daysWithAppointments.contains(_dayKey(d));

        return GestureDetector(
          onTap: () async {
            setState(() => _selectedDay = d);
            await _loadAppointments();
          },
          child: Container(
            width: 36,
            height: 58,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : (isToday
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  labels[i],
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: isSelected ? AppTheme.rosePrimary : Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${d.day}',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.rosePrimary : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                if (hasAppointment)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.rosePrimary : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 6),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDaySummary() {
    final total = _appointments
        .where((a) => a.status == 'completed')
        .fold<double>(0, (s, a) => s + a.value);
    final count = _appointments.length;

    return Container(
      color: AppTheme.roseLight,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _summaryChip(
            Icons.event,
            '$count agendamentos',
            AppTheme.rosePrimary,
          ),
          const SizedBox(width: 12),
          _summaryChip(
            Icons.attach_money,
            'R\$ ${total.toStringAsFixed(2)}',
            AppTheme.gold,
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.lato(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 72,
            color: AppTheme.roseLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum agendamento neste dia',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textLight,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appt) {
    final statusColor = appt.status == 'completed'
        ? AppTheme.success
        : appt.status == 'cancelled'
            ? AppTheme.error
            : AppTheme.rosePrimary;

    final statusLabel = appt.status == 'completed'
        ? 'Concluído'
        : appt.status == 'cancelled'
            ? 'Cancelado'
            : 'Agendado';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.rosePrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('HH:mm').format(appt.dateTime),
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.rosePrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.lato(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.roseLight,
                  child: Text(
                    appt.clientName[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      color: AppTheme.rosePrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appt.clientName,
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Text(
                  'R\$ ${appt.value.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.roseLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.content_cut,
                    size: 14,
                    color: AppTheme.rosePrimary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appt.description,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appt.status == 'scheduled') ...[
                  _actionBtn(
                    Icons.check_circle_outline,
                    'Concluir',
                    AppTheme.success,
                    () => _updateStatus(appt, 'completed'),
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    Icons.cancel_outlined,
                    'Cancelar',
                    AppTheme.error,
                    () => _updateStatus(appt, 'cancelled'),
                  ),
                  const SizedBox(width: 8),
                ],
                _actionBtn(
                  Icons.edit_outlined,
                  'Editar',
                  AppTheme.rosePrimary,
                  () => _openForm(appt: appt),
                ),
                const SizedBox(width: 8),
                _actionBtn(
                  Icons.delete_outline,
                  'Excluir',
                  AppTheme.textLight,
                  () => _confirmDelete(appt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(Appointment appt, String status) async {
    appt.status = status;
    await FirestoreService.saveAppointment(appt);
    await _loadAppointments();
  }

  void _openForm({Appointment? appt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppointmentForm(
        appointment: appt,
        initialDate: _selectedDay,
        onSaved: _loadAppointments,
      ),
    );
  }

  void _confirmDelete(Appointment appt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Excluir agendamento?',
          style: GoogleFonts.playfairDisplay(),
        ),
        content: Text(
          'Esta ação não pode ser desfeita.',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.lato()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await FirestoreService.deleteAppointment(appt.id);
              await _loadAppointments();
              if (mounted) Navigator.pop(context);
            },
            child: Text('Excluir', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );
  }
}

class _AppointmentForm extends StatefulWidget {
  final Appointment? appointment;
  final DateTime initialDate;
  final Future<void> Function() onSaved;

  const _AppointmentForm({
    this.appointment,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<_AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<_AppointmentForm> {
  final _formKey = GlobalKey<FormState>();

  Client? _selectedClient;
  late DateTime _date;
  late TimeOfDay _time;
  bool _saving = false;

  late final TextEditingController _descCtrl =
      TextEditingController(text: widget.appointment?.description);

  late final TextEditingController _valueCtrl = TextEditingController(
    text: widget.appointment?.value.toStringAsFixed(2) ?? '',
  );

  List<Client> _clients = [];
  bool _loadingClients = true;

  @override
  void initState() {
    super.initState();
    _date = widget.appointment?.dateTime ?? widget.initialDate;
    _time = widget.appointment != null
        ? TimeOfDay.fromDateTime(widget.appointment!.dateTime)
        : TimeOfDay.now();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await FirestoreService.clientsStream().first;
      Client? selected;

      if (widget.appointment != null) {
        for (final c in clients) {
          if (c.id == widget.appointment!.clientId) {
            selected = c;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _clients = clients;
          _selectedClient = selected;
          _loadingClients = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingClients = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar clientes.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateCustom() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _CustomDatePickerDialog(initialDate: _date),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: _loadingClients
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.appointment == null
                          ? 'Novo Agendamento'
                          : 'Editar Agendamento',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<Client>(
                      value: _selectedClient,
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        prefixIcon:
                            Icon(Icons.person, color: AppTheme.rosePrimary),
                      ),
                      items: _clients
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name, style: GoogleFonts.lato()),
                            ),
                          )
                          .toList(),
                      onChanged: (c) => setState(() => _selectedClient = c),
                      validator: (v) =>
                          v == null ? 'Selecione uma cliente' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dateTile(
                            icon: Icons.calendar_today,
                            label: DateFormat('dd/MM/yyyy').format(_date),
                            onTap: _pickDateCustom,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateTile(
                            icon: Icons.access_time,
                            label: _time.format(context),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Descreva o serviço'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Descrição do serviço',
                        prefixIcon: Icon(Icons.content_cut,
                            color: AppTheme.rosePrimary),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _valueCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe o valor';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)',
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: AppTheme.rosePrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving
                              ? 'Salvando...'
                              : (widget.appointment == null
                                  ? 'Agendar'
                                  : 'Salvar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _dateTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.rosePrimary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.rosePrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lato(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) return;

    setState(() => _saving = true);

    try {
      final dateTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

      final appt = Appointment(
        id: widget.appointment?.id ?? const Uuid().v4(),
        clientId: _selectedClient!.id,
        clientName: _selectedClient!.name,
        dateTime: dateTime,
        description: _descCtrl.text.trim(),
        value: double.parse(_valueCtrl.text.replaceAll(',', '.')),
        status: widget.appointment?.status ?? 'scheduled',
        createdAt: widget.appointment?.createdAt ?? DateTime.now(),
      );

      await FirestoreService.saveAppointment(appt);
      await widget.onSaved();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar agendamento.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _CustomDatePickerDialog({required this.initialDate});

  @override
  State<_CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  bool _loading = true;
  Set<String> _daysWithAppointments = {};

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _visibleMonth =
        DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _loadMonthDots();
  }

  Future<void> _loadMonthDots() async {
    setState(() => _loading = true);
    try {
      final monthData = await FirestoreService.getAppointmentsByMonth(
        _visibleMonth.year,
        _visibleMonth.month,
      );

      if (mounted) {
        setState(() {
          _daysWithAppointments =
              monthData.map((a) => _dayKey(a.dateTime)).toSet();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _changeMonth(int offset) async {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + offset, 1);
    });
    await _loadMonthDots();
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final firstWeekday = firstDay.weekday % 7;

    final days = <DateTime?>[];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_visibleMonth.year, _visibleMonth.month, i));
    }

    while (days.length % 7 != 0) {
      days.add(null);
    }

    return Dialog(
      backgroundColor: const Color(0xFFF7E9EE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: 650,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 190,
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E3E8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecione a data',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      DateFormat("EEE., d\n'de' MMM.", 'pt_BR')
                          .format(_selectedDate)
                          .toLowerCase(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        color: AppTheme.textDark,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('MMMM y', 'pt_BR')
                                .format(_visibleMonth)
                                .toLowerCase(),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _changeMonth(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          _WeekLabel('D'),
                          _WeekLabel('S'),
                          _WeekLabel('T'),
                          _WeekLabel('Q'),
                          _WeekLabel('Q'),
                          _WeekLabel('S'),
                          _WeekLabel('S'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        )
                      else
                        ...List.generate(days.length ~/ 7, (weekIndex) {
                          final week =
                              days.skip(weekIndex * 7).take(7).toList();
                          return Row(
                            children: week.map((day) {
                              if (day == null) {
                                return const Expanded(
                                  child: SizedBox(height: 54),
                                );
                              }

                              final isSelected =
                                  day.year == _selectedDate.year &&
                                      day.month == _selectedDate.month &&
                                      day.day == _selectedDate.day;

                              final hasAppointment =
                                  _daysWithAppointments.contains(_dayKey(day));

                              return Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: () {
                                    setState(() => _selectedDate = day);
                                  },
                                  child: SizedBox(
                                    height: 54,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppTheme.rosePrimary
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: !isSelected &&
                                                    day.year ==
                                                        DateTime.now().year &&
                                                    day.month ==
                                                        DateTime.now().month &&
                                                    day.day ==
                                                        DateTime.now().day
                                                ? Border.all(
                                                    color: AppTheme.rosePrimary
                                                        .withOpacity(0.6),
                                                  )
                                                : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${day.day}',
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.textDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        if (hasAppointment)
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.rosePrimary,
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        else
                                          const SizedBox(height: 6),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, _selectedDate),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  final String text;

  const _WeekLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 14,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
