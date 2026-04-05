import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/assignment.dart';
import '../../core/models/schedule.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import 'add_schedule_screen.dart';
import '../../core/constants/app_constants.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Schedule> _schedules = [];
  List<Subject> _subjects = [];
  List<Assignment> _assignments = [];
  bool _isLoading = true;

  // Calendar state
  bool _showCalendar = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      DatabaseHelper.instance.getSchedules(),
      DatabaseHelper.instance.getSubjects(),
      DatabaseHelper.instance.getAssignments(),
    ]);
    setState(() {
      _schedules = results[0] as List<Schedule>;
      _subjects = results[1] as List<Subject>;
      _assignments = results[2] as List<Assignment>;
      _isLoading = false;
    });
  }

  Subject? _getSubject(int id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Schedule> _getByDay(int day) =>
      _schedules.where((s) => s.type == 'class' && s.dayOfWeek == day).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  List<Schedule> get _exams =>
      _schedules.where((s) => s.type == 'exam').toList()
        ..sort((a, b) => (a.date ?? '').compareTo(b.date ?? ''));

  // Events for a specific calendar day
  List<dynamic> _eventsForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final events = <dynamic>[];

    // Exams on this date
    events.addAll(_schedules.where((s) => s.type == 'exam' && s.date == dateStr));

    // Assignments due on this date
    events.addAll(_assignments.where((a) => a.deadline == dateStr));

    // Classes on this weekday
    final weekday = day.weekday - 1; // Mon=0
    events.addAll(
      _schedules.where((s) => s.type == 'class' && s.dayOfWeek == weekday),
    );

    return events;
  }

  List<dynamic> _selectedDayEvents() => _eventsForDay(_selectedDay);

  Future<void> _delete(Schedule s) async {
    final confirmed = await showConfirmDelete(
      context,
      title: 'Delete Schedule',
      content: 'Delete this schedule entry?',
    );
    if (confirmed) {
      await DatabaseHelper.instance.deleteSchedule(s.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: Icon(_showCalendar ? Icons.list : Icons.calendar_month),
            tooltip: _showCalendar ? 'List View' : 'Calendar View',
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
        ],
        bottom: _showCalendar
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(icon: Icon(Icons.class_outlined), text: 'Classes'),
                  Tab(icon: Icon(Icons.event_outlined), text: 'Exams'),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showCalendar
          ? _buildCalendarView()
          : TabBarView(
              controller: _tabController,
              children: [_buildClassTab(), _buildExamTab()],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddScheduleScreen(
                subjects: _subjects,
                initialType:
                    _showCalendar || _tabController.index == 0
                    ? 'class'
                    : 'exam',
              ),
            ),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── CALENDAR VIEW ───────────────────────────────────────
  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _eventsForDay,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppTheme.orange,
              shape: BoxShape.circle,
            ),
            markerSize: 6,
            markersMaxCount: 3,
          ),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
        ),
        const Divider(height: 1),
        Expanded(child: _buildSelectedDayEvents()),
      ],
    );
  }

  Widget _buildSelectedDayEvents() {
    final events = _selectedDayEvents();
    final dateStr = DateFormat('EEE, d MMM').format(_selectedDay);

    if (events.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              dateStr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Nothing on this day',
            subtitle: 'No classes, exams, or deadlines',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            dateStr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        ...events.map((e) {
          if (e is Schedule) return _buildScheduleCard(e);
          if (e is Assignment) return _buildAssignmentEventCard(e);
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildAssignmentEventCard(Assignment a) {
    final subject = _getSubject(a.subjectId);
    final color = subject != null
        ? AppTheme.fromHex(subject.color)
        : AppTheme.warning;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.priorityColor(a.priority),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          a.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            SubjectDot(color: color, radius: 4),
            const SizedBox(width: 6),
            Text(subject?.name ?? 'Unknown', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.assignment_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            const Text('Due', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: PriorityBadge(priority: a.priority),
      ),
    );
  }

  // ── CLASS TAB (list view) ────────────────────────────────
  Widget _buildClassTab() {
    final hasAny = _schedules.any((s) => s.type == 'class');
    if (!hasAny) {
      return const EmptyState(
        icon: Icons.class_outlined,
        title: 'No classes scheduled',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 7,
        itemBuilder: (context, dayIndex) {
          final daySchedules = _getByDay(dayIndex);
          if (daySchedules.isEmpty) return const SizedBox.shrink();
          final isToday = DateTime.now().weekday - 1 == dayIndex;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConstants.days[dayIndex],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppTheme.primary : Colors.grey.shade600,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...daySchedules.map((s) => _buildScheduleCard(s)),
            ],
          );
        },
      ),
    );
  }

  // ── EXAM TAB (list view) ─────────────────────────────────
  Widget _buildExamTab() {
    if (_exams.isEmpty) {
      return const EmptyState(
        icon: Icons.event_outlined,
        title: 'No exams scheduled',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _exams.length,
        itemBuilder: (_, i) => _buildScheduleCard(_exams[i]),
      ),
    );
  }

  Widget _buildScheduleCard(Schedule s) {
    final subject = _getSubject(s.subjectId);
    final color =
        subject != null ? AppTheme.fromHex(subject.color) : Colors.grey;
    final isExam = s.type == 'exam';
    final examDate = isExam ? DateTime.tryParse(s.date ?? '') : null;
    final daysLeft = examDate != null
        ? examDate.difference(DateTime.now()).inDays
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          subject?.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${s.startTime} – ${s.endTime}'
          '${s.room.isNotEmpty ? '  ·  ${s.room}' : ''}'
          '${isExam && s.date != null ? '  ·  ${s.date}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (daysLeft != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (daysLeft <= 3 ? AppTheme.danger : AppTheme.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$daysLeft d',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: daysLeft <= 3 ? AppTheme.danger : AppTheme.warning,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'edit') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddScheduleScreen(
                        subjects: _subjects,
                        schedule: s,
                        initialType: s.type,
                      ),
                    ),
                  );
                  _loadData();
                }
                if (val == 'delete') _delete(s);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
