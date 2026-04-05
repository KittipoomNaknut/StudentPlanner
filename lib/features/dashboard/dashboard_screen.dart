import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/assignment.dart';
import '../../core/models/schedule.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../subject/subject_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;

  const DashboardScreen({super.key, required this.onThemeChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Subject> _subjects = [];
  List<Assignment> _pendingTasks = [];
  List<Schedule> _todayClasses = [];
  List<Schedule> _upcomingExams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;

    final results = await Future.wait([
      db.getSubjects(),
      db.getAssignments(status: 'pending'),
      db.getSchedules(type: 'class'),
      db.getSchedules(type: 'exam'),
    ]);

    final subjects = results[0] as List<Subject>;
    final pending = results[1] as List<Assignment>;
    final classes = results[2] as List<Schedule>;
    final exams = results[3] as List<Schedule>;

    final todayIndex = DateTime.now().weekday - 1;
    final todayClasses =
        classes.where((s) => s.dayOfWeek == todayIndex).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    final upcoming = exams.where((e) {
      final d = DateTime.tryParse(e.date ?? '');
      return d != null && d.isAfter(now) && d.isBefore(nextWeek);
    }).toList();

    setState(() {
      _subjects = subjects;
      _pendingTasks = pending;
      _todayClasses = todayClasses;
      _upcomingExams = upcoming;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Planner'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SettingsScreen(onThemeChanged: widget.onThemeChanged),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 16),
                  _buildStatRow(),
                  const SizedBox(height: 12),
                  _buildManageSubjectsCard(),
                  const SizedBox(height: 24),
                  if (_todayClasses.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Today\'s Classes',
                      Icons.class_outlined,
                    ),
                    ..._todayClasses.map(_buildClassCard),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionHeader(
                    'Pending Tasks (${_pendingTasks.length})',
                    Icons.assignment_outlined,
                  ),
                  if (_pendingTasks.isEmpty)
                    _buildEmptyCard('No pending tasks 🎉')
                  else
                    ..._pendingTasks.take(5).map(_buildTaskCard),
                  if (_pendingTasks.length > 5)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '+${_pendingTasks.length - 5} more tasks',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_upcomingExams.isNotEmpty) ...[
                    _buildSectionHeader('Upcoming Exams', Icons.event_outlined),
                    ..._upcomingExams.map(_buildExamCard),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final today = DateFormat('EEEE, dd MMM').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          today,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatRow() {
    final overdue = _pendingTasks.where((a) => a.isOverdue).length;
    return Row(
      children: [
        _buildStatCard(
          'Subjects',
          '${_subjects.length}',
          Icons.book,
          AppTheme.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Tasks',
          '${_pendingTasks.length}',
          Icons.assignment,
          AppTheme.warning,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Overdue',
          '$overdue',
          Icons.warning,
          overdue > 0 ? AppTheme.danger : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildManageSubjectsCard() {
    return Card(
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubjectScreen()),
          );
          _loadData();
        },
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.menu_book, color: AppTheme.primary),
        ),
        title: const Text(
          'Manage Subjects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_subjects.length} subject${_subjects.length != 1 ? 's' : ''} enrolled',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildClassCard(Schedule s) {
    final subject = _getSubject(s.subjectId);
    final color = subject != null
        ? AppTheme.fromHex(subject.color)
        : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
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
          '${s.room.isNotEmpty ? '  •  ${s.room}' : ''}',
        ),
        trailing: Icon(Icons.class_, color: color),
      ),
    );
  }

  Widget _buildTaskCard(Assignment a) {
    final subject = _getSubject(a.subjectId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.priorityColor(
            a.priority,
          ).withValues(alpha: 0.15),
          child: Icon(
            Icons.assignment_outlined,
            color: AppTheme.priorityColor(a.priority),
            size: 18,
          ),
        ),
        title: Text(
          a.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${subject?.name ?? ''}  •  Due ${a.deadline}'
          '${a.isOverdue ? '  ⚠️ Overdue' : ''}',
          style: TextStyle(color: a.isOverdue ? AppTheme.danger : null),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.priorityColor(a.priority).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            a.priority.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.priorityColor(a.priority),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(Schedule s) {
    final subject = _getSubject(s.subjectId);
    final color = subject != null
        ? AppTheme.fromHex(subject.color)
        : Colors.grey;
    final examDate = DateTime.tryParse(s.date ?? '');
    final daysLeft = examDate != null
        ? examDate.difference(DateTime.now()).inDays
        : 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.event, color: color),
        ),
        title: Text(
          subject?.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${s.date}  •  ${s.startTime}'
          '${s.room.isNotEmpty ? '  •  ${s.room}' : ''}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$daysLeft',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: daysLeft <= 2 ? AppTheme.danger : AppTheme.warning,
              ),
            ),
            Text(
              'days',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
