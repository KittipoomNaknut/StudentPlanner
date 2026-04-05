import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/schedule.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // TabController สำหรับ class / exam tab
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
    final schedules = await DatabaseHelper.instance.getSchedules();
    final subjects = await DatabaseHelper.instance.getSubjects();
    setState(() {
      _schedules = schedules;
      _subjects = subjects;
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

  Future<void> _delete(Schedule s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Delete this schedule entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteSchedule(s.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        bottom: TabBar(
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
                initialType: _tabController.index == 0 ? 'class' : 'exam',
              ),
            ),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── CLASS TAB — แสดงตามวัน ──────────────────────────
  Widget _buildClassTab() {
    final hasAny = _schedules.any((s) => s.type == 'class');
    if (!hasAny) return _buildEmptyState('No classes scheduled', 'class');

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: 7,
      itemBuilder: (context, dayIndex) {
        final daySchedules = _getByDay(dayIndex);
        if (daySchedules.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                AppConstants.days[dayIndex],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
            ...daySchedules.map((s) => _buildScheduleCard(s)),
          ],
        );
      },
    );
  }

  // ── EXAM TAB — เรียงตามวันที่ ──────────────────────
  Widget _buildExamTab() {
    if (_exams.isEmpty) return _buildEmptyState('No exams scheduled', 'exam');
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _exams.length,
      itemBuilder: (_, i) => _buildScheduleCard(_exams[i]),
    );
  }

  Widget _buildScheduleCard(Schedule s) {
    final subject = _getSubject(s.subjectId);
    final color = subject != null
        ? AppTheme.fromHex(subject.color)
        : Colors.grey;

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
          '${s.room.isNotEmpty ? '  •  ${s.room}' : ''}'
          '${s.type == 'exam' && s.date != null ? '  •  ${s.date}' : ''}',
        ),
        trailing: PopupMenuButton<String>(
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
      ),
    );
  }

  Widget _buildEmptyState(String message, String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'class' ? Icons.class_outlined : Icons.event_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text('Tap + to add', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
