import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDay = DateTime.now();
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    setState(() {
      _appointments = StorageService.getAppointmentsByDay(_selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildDatePicker(),
          _buildDaySummary(),
          Expanded(
            child: _appointments.isEmpty
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
                onPressed: () {
                  setState(() {
                    _selectedDay =
                        _selectedDay.subtract(const Duration(days: 1));
                  });
                  _loadAppointments();
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
                onPressed: () {
                  setState(() {
                    _selectedDay = _selectedDay.add(const Duration(days: 1));
                  });
                  _loadAppointments();
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

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDay = d);
            _loadAppointments();
          },
          child: Container(
            width: 36,
            height: 52,
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
    await StorageService.saveAppointment(appt);
    _loadAppointments();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _selectedDay = picked);
      _loadAppointments();
    }
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
              await StorageService.deleteAppointment(appt.id);
              _loadAppointments();
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
  final VoidCallback onSaved;

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

  late final TextEditingController _descCtrl =
      TextEditingController(text: widget.appointment?.description);

  late final TextEditingController _valueCtrl = TextEditingController(
    text: widget.appointment?.value.toStringAsFixed(2) ?? '',
  );

  final _dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _clients = StorageService.getAllClients();
    _date = widget.appointment?.dateTime ?? widget.initialDate;
    _time = widget.appointment != null
        ? TimeOfDay.fromDateTime(widget.appointment!.dateTime)
        : TimeOfDay.now();

    if (widget.appointment != null) {
      _selectedClient = StorageService.getClient(widget.appointment!.clientId);
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
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
        child: Form(
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
                  prefixIcon: Icon(Icons.person, color: AppTheme.rosePrimary),
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
                validator: (v) => v == null ? 'Selecione uma cliente' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      icon: Icons.calendar_today,
                      label: DateFormat('dd/MM/yyyy').format(_date),
                      onTap: _pickDateManual,
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
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Descreva o serviço' : null,
                decoration: const InputDecoration(
                  labelText: 'Descrição do serviço',
                  prefixIcon:
                      Icon(Icons.content_cut, color: AppTheme.rosePrimary),
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
                  prefixIcon:
                      Icon(Icons.attach_money, color: AppTheme.rosePrimary),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(
                    widget.appointment == null ? 'Agendar' : 'Salvar',
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

  DateTime? _parseDate(String value) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDateManual() async {
    final controller = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_date),
    );

    String? errorText;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Selecionar data',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _dateMask,
                    ],
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Inserir data',
                      hintText: 'dd/mm/aaaa',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Exemplo: 20/06/2026',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                IconButton(
                  tooltip: 'Abrir calendário',
                  onPressed: () async {
                    final calendarPicked = await showDatePicker(
                      context: dialogContext,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: const Locale('pt', 'BR'),
                    );

                    if (calendarPicked != null && context.mounted) {
                      Navigator.pop(dialogContext, calendarPicked);
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                ),
                ElevatedButton(
                  onPressed: () {
                    final parsed = _parseDate(controller.text);

                    if (parsed == null) {
                      setLocalState(() {
                        errorText = 'Formato inválido.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, parsed);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (picked != null) {
      setState(() => _date = picked);
    }
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

    await StorageService.saveAppointment(appt);
    widget.onSaved();

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
