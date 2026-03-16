import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedWeek = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDailyReport(),
                _buildWeeklyReport(),
                _buildMonthlyReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.rosePrimary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.today, size: 18), text: 'DIÁRIO'),
          Tab(icon: Icon(Icons.view_week, size: 18), text: 'SEMANAL'),
          Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'MENSAL'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  DIÁRIO
  // ══════════════════════════════════════════════════════════
  Widget _buildDailyReport() {
    final appts = StorageService.getAppointmentsByDay(_selectedDay);
    final completed = appts.where((a) => a.status == 'completed').toList();
    final cancelled = appts.where((a) => a.status == 'cancelled').toList();
    final scheduled = appts.where((a) => a.status == 'scheduled').toList();

    final totalReceita = completed.fold<double>(0, (s, a) => s + a.value);
    final ticketMedio = completed.isEmpty ? 0.0 : totalReceita / completed.length;
    final previsto = scheduled.fold<double>(0, (s, a) => s + a.value);

    final yesterday = _selectedDay.subtract(const Duration(days: 1));
    final yesterdayRevenue = StorageService.revenueForDay(yesterday);
    final diffDay = yesterdayRevenue == 0
        ? null
        : ((totalReceita - yesterdayRevenue) / yesterdayRevenue * 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayNav(),
          const SizedBox(height: 16),
          _buildFinancialHero(
            label: 'Receita do Dia',
            value: _currency.format(totalReceita),
            diff: diffDay,
            diffLabel: 'vs ontem',
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _kpiSmall('Atendimentos', '${completed.length}', Icons.check_circle_outline, AppTheme.success)),
            const SizedBox(width: 10),
            Expanded(child: _kpiSmall('Ticket Médio', 'R\$ ${ticketMedio.toStringAsFixed(2)}', Icons.receipt_long, AppTheme.rosePrimary)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _kpiSmall('A Receber (agend.)', 'R\$ ${previsto.toStringAsFixed(2)}', Icons.schedule, AppTheme.gold)),
            const SizedBox(width: 10),
            Expanded(child: _kpiSmall('Cancelamentos', '${cancelled.length}', Icons.cancel_outlined, AppTheme.error)),
          ]),
          const SizedBox(height: 20),
          if (completed.isNotEmpty) ...[
            _sectionHeader('Atendimentos Concluídos', completed.length),
            const SizedBox(height: 10),
            ...completed.map((a) => _financialRow(a)),
            const SizedBox(height: 8),
            _totalRow('Total do dia', totalReceita),
          ] else
            _emptyState('Nenhum atendimento concluído neste dia'),
          if (scheduled.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('A Receber (Agendados)', scheduled.length),
            const SizedBox(height: 10),
            ...scheduled.map((a) => _financialRow(a, pending: true)),
            const SizedBox(height: 8),
            _totalRow('Previsto', previsto, color: AppTheme.gold),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SEMANAL
  // ══════════════════════════════════════════════════════════
  Widget _buildWeeklyReport() {
    final weekStart = _getMonday(_selectedWeek);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    final appts = StorageService.getAppointmentsByWeek(_selectedWeek);
    final completed = appts.where((a) => a.status == 'completed').toList();
    final cancelled = appts.where((a) => a.status == 'cancelled').toList();

    final totalReceita = completed.fold<double>(0, (s, a) => s + a.value);
    final ticketMedio = completed.isEmpty ? 0.0 : totalReceita / completed.length;

    final dailyRevenues = days.map((d) => completed
        .where((a) => _sameDay(a.dateTime, d))
        .fold<double>(0, (s, a) => s + a.value)).toList();

    final prevWeek = _selectedWeek.subtract(const Duration(days: 7));
    final prevRevenue = StorageService.revenueForWeek(prevWeek);
    final diffWeek = prevRevenue == 0
        ? null
        : ((totalReceita - prevRevenue) / prevRevenue * 100);

    double bestVal = 0;
    int bestIdx = -1;
    for (int i = 0; i < dailyRevenues.length; i++) {
      if (dailyRevenues[i] > bestVal) {
        bestVal = dailyRevenues[i];
        bestIdx = i;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeekNav(weekStart),
          const SizedBox(height: 16),
          _buildFinancialHero(
            label: 'Receita da Semana',
            value: _currency.format(totalReceita),
            diff: diffWeek,
            diffLabel: 'vs semana anterior',
            icon: Icons.view_week,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _kpiSmall('Atendimentos', '${completed.length}', Icons.check_circle_outline, AppTheme.success)),
            const SizedBox(width: 10),
            Expanded(child: _kpiSmall('Ticket Médio', 'R\$ ${ticketMedio.toStringAsFixed(2)}', Icons.receipt_long, AppTheme.rosePrimary)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _kpiSmall(
              'Melhor Dia',
              bestIdx >= 0 ? dayLabels[bestIdx] : '-',
              Icons.star_outline, AppTheme.gold,
            )),
            const SizedBox(width: 10),
            Expanded(child: _kpiSmall('Cancelamentos', '${cancelled.length}', Icons.cancel_outlined, AppTheme.error)),
          ]),
          const SizedBox(height: 20),
          _sectionHeader('Receita por Dia', null),
          const SizedBox(height: 12),
          _buildBarChart(dailyRevenues, dayLabels),
          const SizedBox(height: 20),
          _sectionHeader('Detalhamento por Dia', null),
          const SizedBox(height: 10),
          ...List.generate(7, (i) {
            final d = days[i];
            final dayCompleted = completed.where((a) => _sameDay(a.dateTime, d)).toList();
            if (dayCompleted.isEmpty) return const SizedBox.shrink();
            return _buildDayBlock(dayLabels[i], d, dayCompleted, dailyRevenues[i]);
          }),
          if (completed.isEmpty) _emptyState('Nenhum atendimento concluído nesta semana'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MENSAL
  // ══════════════════════════════════════════════════════════
  Widget _buildMonthlyReport() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final appts = StorageService.getAppointmentsByMonth(year, month);
    final completed = appts.where((a) => a.status == 'completed').toList();
    final cancelled = appts.where((a) => a.status == 'cancelled').toList();

    final totalReceita = completed.fold<double>(0, (s, a) => s + a.value);
    final ticketMedio = completed.isEmpty ? 0.0 : totalReceita / completed.length;

    final prevMonth = DateTime(year, month - 1);
    final prevRevenue = StorageService.revenueForMonth(prevMonth.year, prevMonth.month);
    final diffMonth = prevRevenue == 0
        ? null
        : ((totalReceita - prevRevenue) / prevRevenue * 100);

    final weekRevenues = List.generate(5, (w) {
      final startDay = w * 7 + 1;
      return completed.where((a) {
        final d = a.dateTime.day;
        return d >= startDay && d < startDay + 7;
      }).fold<double>(0, (s, a) => s + a.value);
    });

    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final dailyRevs = List.generate(daysInMonth, (i) {
      final d = DateTime(year, month, i + 1);
      return completed
          .where((a) => _sameDay(a.dateTime, d))
          .fold<double>(0, (s, a) => s + a.value);
    });

    double bestDayVal = 0;
    int bestDayNum = 0;
    for (int i = 0; i < dailyRevs.length; i++) {
      if (dailyRevs[i] > bestDayVal) {
        bestDayVal = dailyRevs[i];
        bestDayNum = i + 1;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthNav(),
          const SizedBox(height: 16),
          _buildFinancialHero(
            label: 'Receita do Mês',
            value: _currency.format(totalReceita),
            diff: diffMonth,
            diffLabel: 'vs mês anterior',
            icon: Icons.calendar_month,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _kpiSmall('Atendimentos', '${completed.length}', Icons.check_circle_outline, AppTheme.success)),
            const SizedBox(width: 10),
            Expanded(child: _kpiSmall('Ticket Médio', 'R\$ ${ticketMedio.toStringAsFixed(2)}', Icons.receipt_long, AppTheme.rosePrimary)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _kpiSmall(
              'Melhor Dia',
              bestDayNum > 0 ? 'Dia $bestDayNum' : '-',
              Icons.star_outline, AppTheme.gold,
            )),
            const SizedBox(width: 10),
            Expanded(child: _kpiSmall('Cancelamentos', '${cancelled.length}', Icons.cancel_outlined, AppTheme.error)),
          ]),
          const SizedBox(height: 20),
          _sectionHeader('Receita por Semana', null),
          const SizedBox(height: 12),
          _buildBarChart(weekRevenues, ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5']),
          const SizedBox(height: 20),
          _sectionHeader('Evolução Diária', null),
          const SizedBox(height: 12),
          _buildLineChart(dailyRevs, daysInMonth),
          const SizedBox(height: 20),
          if (completed.isNotEmpty) ...[
            _sectionHeader('Resumo por Semana', null),
            const SizedBox(height: 10),
            _buildWeekSummaryTable(completed),
            const SizedBox(height: 8),
            _totalRow('Total do mês', totalReceita),
          ] else
            _emptyState('Nenhum atendimento concluído neste mês'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  NAVEGAÇÃO
  // ══════════════════════════════════════════════════════════
  Widget _buildDayNav() {
    return _navContainer(
      onPrev: () => setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 1))),
      onNext: () => setState(() => _selectedDay = _selectedDay.add(const Duration(days: 1))),
      onTap: () async {
        final p = await showDatePicker(
          context: context,
          initialDate: _selectedDay,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          locale: const Locale('pt', 'BR'),
        );
        if (p != null) setState(() => _selectedDay = p);
      },
      topLabel: DateFormat('EEEE', 'pt_BR').format(_selectedDay).toUpperCase(),
      mainLabel: DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(_selectedDay),
    );
  }

  Widget _buildWeekNav(DateTime weekStart) {
    return _navContainer(
      onPrev: () => setState(() => _selectedWeek = _selectedWeek.subtract(const Duration(days: 7))),
      onNext: () => setState(() => _selectedWeek = _selectedWeek.add(const Duration(days: 7))),
      topLabel: 'SEMANA',
      mainLabel:
          '${DateFormat('d/MM', 'pt_BR').format(weekStart)} – ${DateFormat("d/MM/y", 'pt_BR').format(weekStart.add(const Duration(days: 6)))}',
    );
  }

  Widget _buildMonthNav() {
    return _navContainer(
      onPrev: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
      onNext: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
      topLabel: 'MÊS',
      mainLabel: DateFormat("MMMM 'de' y", 'pt_BR').format(_selectedMonth),
    );
  }

  Widget _navContainer({
    required VoidCallback onPrev,
    required VoidCallback onNext,
    VoidCallback? onTap,
    required String topLabel,
    required String mainLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppTheme.rosePrimary.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left, color: AppTheme.rosePrimary), onPressed: onPrev),
          GestureDetector(
            onTap: onTap,
            child: Column(children: [
              Text(topLabel, style: GoogleFonts.lato(color: AppTheme.textLight, fontSize: 11, letterSpacing: 1.5)),
              Text(mainLabel,
                  style: GoogleFonts.playfairDisplay(
                      color: AppTheme.textDark, fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          ),
          IconButton(icon: const Icon(Icons.chevron_right, color: AppTheme.rosePrimary), onPressed: onNext),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  WIDGETS VISUAIS
  // ══════════════════════════════════════════════════════════
  Widget _buildFinancialHero({
    required String label,
    required String value,
    required double? diff,
    required String diffLabel,
    required IconData icon,
  }) {
    final isPositive = (diff ?? 0) >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.rosePrimary, AppTheme.roseDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppTheme.rosePrimary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.lato(color: Colors.white70, fontSize: 13, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        if (diff != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.greenAccent : Colors.redAccent, size: 16),
            const SizedBox(width: 4),
            Text(
              '${isPositive ? '+' : ''}${diff.toStringAsFixed(1)}% $diffLabel',
              style: GoogleFonts.lato(
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _kpiSmall(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: GoogleFonts.playfairDisplay(color: color, fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
          Text(label, style: GoogleFonts.lato(color: AppTheme.textMedium, fontSize: 10), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _sectionHeader(String title, int? count) {
    return Row(children: [
      Text(title,
          style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      if (count != null) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppTheme.roseLight, borderRadius: BorderRadius.circular(10)),
          child: Text('$count',
              style: GoogleFonts.lato(color: AppTheme.rosePrimary, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    ]);
  }

  Widget _financialRow(Appointment a, {bool pending = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: pending ? Border.all(color: AppTheme.gold.withOpacity(0.3)) : null,
        boxShadow: [BoxShadow(color: AppTheme.rosePrimary.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: pending ? AppTheme.goldLight : AppTheme.roseLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(DateFormat('HH:mm').format(a.dateTime),
              style: GoogleFonts.lato(
                  color: pending ? AppTheme.gold : AppTheme.rosePrimary,
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.clientName, style: GoogleFonts.lato(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: 14)),
          Text(a.description,
              style: GoogleFonts.lato(fontSize: 12, color: AppTheme.textMedium),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Text('R\$ ${a.value.toStringAsFixed(2)}',
            style: GoogleFonts.lato(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    );
  }

  Widget _totalRow(String label, double value, {Color? color}) {
    final c = color ?? AppTheme.rosePrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.lato(fontWeight: FontWeight.w700, color: c, fontSize: 14)),
        Text('R\$ ${value.toStringAsFixed(2)}',
            style: GoogleFonts.playfairDisplay(color: c, fontWeight: FontWeight.bold, fontSize: 18)),
      ]),
    );
  }

  Widget _buildDayBlock(String dayLabel, DateTime day, List<Appointment> appts, double revenue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppTheme.rosePrimary.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.roseLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$dayLabel — ${DateFormat('d/MM', 'pt_BR').format(day)}',
                style: GoogleFonts.lato(fontWeight: FontWeight.w700, color: AppTheme.rosePrimary)),
            Text('R\$ ${revenue.toStringAsFixed(2)}',
                style: GoogleFonts.playfairDisplay(color: AppTheme.rosePrimary, fontWeight: FontWeight.bold)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: appts.map((a) => _financialRow(a)).toList()),
        ),
      ]),
    );
  }

  Widget _buildWeekSummaryTable(List<Appointment> completed) {
    final rows = List.generate(5, (w) {
      final startDay = w * 7 + 1;
      final weekAppts = completed.where((a) {
        final d = a.dateTime.day;
        return d >= startDay && d < startDay + 7;
      }).toList();
      final rev = weekAppts.fold<double>(0, (s, a) => s + a.value);
      return {'week': w + 1, 'count': weekAppts.length, 'revenue': rev};
    }).where((r) => (r['count'] as int) > 0).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppTheme.rosePrimary.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.roseLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Expanded(child: Text('Semana', style: GoogleFonts.lato(fontWeight: FontWeight.w700, color: AppTheme.rosePrimary, fontSize: 13))),
            Text('Atend.', style: GoogleFonts.lato(fontWeight: FontWeight.w700, color: AppTheme.rosePrimary, fontSize: 13)),
            const SizedBox(width: 24),
            SizedBox(width: 100, child: Text('Receita', textAlign: TextAlign.right, style: GoogleFonts.lato(fontWeight: FontWeight.w700, color: AppTheme.rosePrimary, fontSize: 13))),
          ]),
        ),
        ...rows.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: i % 2 == 0 ? Colors.white : AppTheme.surface,
              borderRadius: i == rows.length - 1
                  ? const BorderRadius.vertical(bottom: Radius.circular(14))
                  : null,
            ),
            child: Row(children: [
              Expanded(child: Text('Semana ${r['week']}', style: GoogleFonts.lato(color: AppTheme.textDark))),
              Text('${r['count']}x', style: GoogleFonts.lato(color: AppTheme.textMedium, fontWeight: FontWeight.w600)),
              const SizedBox(width: 24),
              SizedBox(
                width: 100,
                child: Text('R\$ ${(r['revenue'] as double).toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.lato(color: AppTheme.gold, fontWeight: FontWeight.bold)),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildBarChart(List<double> values, List<String> labels) {
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 180,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.35 + 1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppTheme.roseDark,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              'R\$ ${rod.toY.toStringAsFixed(2)}',
              GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[i], style: GoogleFonts.lato(fontSize: 11, color: AppTheme.textMedium)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.roseLight, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(values.length, (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              width: 22,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: values[i] == 0
                    ? [AppTheme.roseLight, AppTheme.roseLight]
                    : [AppTheme.roseDark, AppTheme.rosePrimary],
              ),
            ),
          ],
        )),
      )),
    );
  }

  Widget _buildLineChart(List<double> dailyRevs, int daysInMonth) {
    final spots = <FlSpot>[];
    for (int i = 0; i < dailyRevs.length; i++) {
      if (dailyRevs[i] > 0) spots.add(FlSpot(i.toDouble() + 1, dailyRevs[i]));
    }
    if (spots.isEmpty) return _emptyState('Sem dados para este mês');
    final maxY = dailyRevs.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: LineChart(LineChartData(
        minX: 1,
        maxX: daysInMonth.toDouble(),
        minY: 0,
        maxY: maxY * 1.3 + 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.rosePrimary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) =>
                  FlDotCirclePainter(radius: 3, color: AppTheme.rosePrimary, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.rosePrimary.withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (v, _) =>
                  Text('${v.toInt()}', style: GoogleFonts.lato(fontSize: 10, color: AppTheme.textLight)),
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.roseLight, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppTheme.roseDark,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      'Dia ${s.x.toInt()}\nR\$ ${s.y.toStringAsFixed(2)}',
                      GoogleFonts.lato(color: Colors.white, fontSize: 11),
                    ))
                .toList(),
          ),
        ),
      )),
    );
  }

  Widget _emptyState(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Column(children: [
          Icon(Icons.bar_chart_outlined, size: 48, color: AppTheme.roseLight),
          const SizedBox(height: 10),
          Text(msg, style: GoogleFonts.lato(color: AppTheme.textLight, fontSize: 14)),
        ])),
      );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _getMonday(DateTime d) => d.subtract(Duration(days: d.weekday - 1));
}
