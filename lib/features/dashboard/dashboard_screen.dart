import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/assignment.dart';
import '../../core/models/attendance.dart';
import '../../core/models/schedule.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../subject/subject_screen.dart';
import '../settings/settings_screen.dart';
import '../attendance/attendance_screen.dart';
import '../timer/pomodoro_screen.dart';

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
  Map<int, double> _attendanceRates = {};
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
      db.getAttendance(),
    ]);

    final subjects = results[0] as List<Subject>;
    final pending = results[1] as List<Assignment>;
    final classes = results[2] as List<Schedule>;
    final exams = results[3] as List<Schedule>;
    final allAttendance = results[4] as List<Attendance>;

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

    // Calculate attendance rate per subject
    final attendanceRates = <int, double>{};
    for (final s in subjects) {
      final records = allAttendance.where((a) => a.subjectId == s.id).toList();
      if (records.isNotEmpty) {
        final present = records.where((a) => a.isPresent || a.isLate).length;
        attendanceRates[s.id!] = present / records.length;
      }
    }

    setState(() {
      _subjects = subjects;
      _pendingTasks = pending;
      _todayClasses = todayClasses;
      _upcomingExams = upcoming;
      _attendanceRates = attendanceRates;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow(),
                          const SizedBox(height: 16),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          if (_attendanceRates.isNotEmpty) ...[
                            const SectionHeader(
                              title: 'Attendance Warning',
                              icon: Icons.warning_amber_outlined,
                            ),
                            _buildAttendanceWarnings(),
                            const SizedBox(height: 24),
                          ],
                          if (_todayClasses.isNotEmpty) ...[
                            SectionHeader(
                              title: "Today's Classes",
                              icon: Icons.class_outlined,
                            ),
                            ..._todayClasses.map(_buildClassCard),
                            const SizedBox(height: 24),
                          ],
                          SectionHeader(
                            title: 'Pending Tasks (${_pendingTasks.length})',
                            icon: Icons.assignment_outlined,
                          ),
                          if (_pendingTasks.isEmpty)
                            _buildEmptyBanner(
                              'No pending tasks',
                              Icons.check_circle_outline,
                              AppTheme.success,
                            )
                          else
                            ..._pendingTasks.take(5).map(_buildTaskCard),
                          if (_pendingTasks.length > 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Center(
                                child: Text(
                                  '+${_pendingTasks.length - 5} more tasks',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                            ),
                          if (_upcomingExams.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const SectionHeader(
                              title: 'Upcoming Exams',
                              icon: Icons.event_outlined,
                            ),
                            ..._upcomingExams.map(_buildExamCard),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverAppBar() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final today = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());
    final overdue = _pendingTasks.where((a) => a.isOverdue).length;

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadData,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SettingsScreen(onThemeChanged: widget.onThemeChanged),
              ),
            );
            _loadData();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                greeting,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                today,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (overdue > 0)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$overdue overdue task${overdue > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow() {
    final overdue = _pendingTasks.where((a) => a.isOverdue).length;
    return Row(
      children: [
        StatCard(
          label: 'Subjects',
          value: '${_subjects.length}',
          icon: Icons.book_outlined,
          color: AppTheme.primary,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubjectScreen()),
            );
            _loadData();
          },
        ),
        const SizedBox(width: 10),
        StatCard(
          label: 'Tasks',
          value: '${_pendingTasks.length}',
          icon: Icons.assignment_outlined,
          color: AppTheme.warning,
        ),
        const SizedBox(width: 10),
        StatCard(
          label: 'Overdue',
          value: '$overdue',
          icon: Icons.warning_outlined,
          color: overdue > 0 ? AppTheme.danger : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionChip(
          icon: Icons.timer_outlined,
          label: 'Pomodoro',
          color: AppTheme.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PomodoroScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _buildActionChip(
          icon: Icons.fact_check_outlined,
          label: 'Attendance',
          color: AppTheme.teal,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AttendanceScreen(subjects: _subjects),
              ),
            );
            _loadData();
          },
        ),
        const SizedBox(width: 10),
        _buildActionChip(
          icon: Icons.menu_book_outlined,
          label: 'Subjects',
          color: AppTheme.primary,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubjectScreen()),
            );
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceWarnings() {
    final lowAttendance = _subjects.where((s) {
      final rate = _attendanceRates[s.id] ?? 1.0;
      return rate < 0.75;
    }).toList();

    if (lowAttendance.isEmpty) {
      return _buildEmptyBanner(
        'All attendance above 75%',
        Icons.check_circle_outline,
        AppTheme.success,
      );
    }

    return Column(
      children: lowAttendance.map((s) {
        final rate = _attendanceRates[s.id!] ?? 0.0;
        final percent = (rate * 100).toStringAsFixed(0);
        final color = AppTheme.fromHex(s.color);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.danger.withValues(alpha: 0.1),
              child: Icon(Icons.warning_amber, color: AppTheme.danger, size: 20),
            ),
            title: Text(
              s.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Attendance: $percent% (below 75%)'),
            trailing: Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyBanner(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Schedule s) {
    final subject = _getSubject(s.subjectId);
    final color =
        subject != null ? AppTheme.fromHex(subject.color) : Colors.grey;
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
          '${s.room.isNotEmpty ? '  ·  ${s.room}' : ''}',
        ),
        trailing: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.class_, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Assignment a) {
    final subject = _getSubject(a.subjectId);
    final subjectColor =
        subject != null ? AppTheme.fromHex(subject.color) : Colors.grey;
    final deadlineDate = DateTime.tryParse(a.deadline);
    final deadlineStr = deadlineDate != null
        ? DateFormat('d MMM').format(deadlineDate)
        : a.deadline;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            SubjectDot(color: subjectColor, radius: 4),
            const SizedBox(width: 5),
            Text(subject?.name ?? '', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Icon(
              Icons.calendar_today,
              size: 11,
              color: a.isOverdue ? AppTheme.danger : Colors.grey,
            ),
            const SizedBox(width: 3),
            Text(
              deadlineStr,
              style: TextStyle(
                fontSize: 12,
                color: a.isOverdue ? AppTheme.danger : Colors.grey,
                fontWeight: a.isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: PriorityBadge(priority: a.priority),
      ),
    );
  }

  Widget _buildExamCard(Schedule s) {
    final subject = _getSubject(s.subjectId);
    final color =
        subject != null ? AppTheme.fromHex(subject.color) : Colors.grey;
    final examDate = DateTime.tryParse(s.date ?? '');
    final daysLeft = examDate != null
        ? examDate.difference(DateTime.now()).inDays
        : 0;
    final isUrgent = daysLeft <= 2;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.event, color: color, size: 20),
        ),
        title: Text(
          subject?.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${s.date}  ·  ${s.startTime}'
          '${s.room.isNotEmpty ? '  ·  ${s.room}' : ''}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (isUrgent ? AppTheme.danger : AppTheme.warning).withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$daysLeft',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isUrgent ? AppTheme.danger : AppTheme.warning,
                ),
              ),
              Text(
                'days',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
