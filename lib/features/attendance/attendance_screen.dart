import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/attendance.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  final List<Subject> subjects;
  const AttendanceScreen({super.key, required this.subjects});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<int, List<Attendance>> _attendanceMap = {};
  bool _isLoading = true;
  int? _selectedSubjectId;

  List<Subject> get _subjects => widget.subjects;

  @override
  void initState() {
    super.initState();
    if (_subjects.isNotEmpty) _selectedSubjectId = _subjects.first.id;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final all = await DatabaseHelper.instance.getAttendance();
    final map = <int, List<Attendance>>{};
    for (final a in all) {
      map.putIfAbsent(a.subjectId, () => []).add(a);
    }
    setState(() {
      _attendanceMap = map;
      _isLoading = false;
    });
  }

  List<Attendance> get _currentAttendance =>
      _attendanceMap[_selectedSubjectId] ?? [];

  double _attendanceRate(int subjectId) {
    final records = _attendanceMap[subjectId] ?? [];
    if (records.isEmpty) return 0;
    final present = records.where((a) => a.isPresent || a.isLate).length;
    return present / records.length;
  }

  Subject? _getSubject(int id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _markAttendance(String status) async {
    if (_selectedSubjectId == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final existing = await DatabaseHelper.instance.getAttendanceByDate(
      _selectedSubjectId!,
      today,
    );

    final record = existing?.copyWith(status: status) ??
        Attendance(
          subjectId: _selectedSubjectId!,
          date: today,
          status: status,
        );

    await DatabaseHelper.instance.insertAttendance(record);
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as ${status.toUpperCase()} for today'),
          backgroundColor: AppTheme.attendanceColor(status),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteRecord(Attendance a) async {
    final confirmed = await showConfirmDelete(
      context,
      title: 'Delete Record',
      content: 'Remove attendance for ${a.date}?',
    );
    if (confirmed) {
      await DatabaseHelper.instance.deleteAttendance(a.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_subjects.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: const EmptyState(
          icon: Icons.fact_check_outlined,
          title: 'No subjects yet',
          subtitle: 'Add subjects first to track attendance',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryRow(),
                _buildSubjectSelector(),
                if (_selectedSubjectId != null) _buildTodayMarkButtons(),
                const Divider(height: 1),
                Expanded(child: _buildRecordList()),
              ],
            ),
    );
  }

  Widget _buildSummaryRow() {
    return Container(
      height: 90,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: _subjects.length,
        itemBuilder: (_, i) {
          final s = _subjects[i];
          final rate = _attendanceRate(s.id!);
          final pct = (rate * 100).toStringAsFixed(0);
          final color = AppTheme.fromHex(s.color);
          final isLow = rate > 0 && rate < 0.75;

          return GestureDetector(
            onTap: () => setState(() => _selectedSubjectId = s.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedSubjectId == s.id
                    ? color
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLow
                      ? AppTheme.danger
                      : color.withValues(alpha: 0.3),
                  width: isLow ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.name.length > 10 ? '${s.name.substring(0, 10)}…' : s.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _selectedSubjectId == s.id
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rate > 0 ? '$pct%' : 'No data',
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedSubjectId == s.id
                          ? Colors.white70
                          : (isLow ? AppTheme.danger : Colors.grey.shade500),
                      fontWeight: isLow ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectSelector() {
    if (_selectedSubjectId == null) return const SizedBox.shrink();
    final subject = _getSubject(_selectedSubjectId!);
    if (subject == null) return const SizedBox.shrink();

    final records = _currentAttendance;
    final rate = _attendanceRate(_selectedSubjectId!);
    final pct = (rate * 100).toStringAsFixed(1);
    final present = records.where((a) => a.isPresent).length;
    final late = records.where((a) => a.isLate).length;
    final absent = records.where((a) => a.isAbsent).length;
    final color = AppTheme.fromHex(subject.color);
    final isLow = rate > 0 && rate < 0.75;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isLow)
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: Colors.yellowAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Below 75% threshold!',
                            style: TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Text(
                records.isEmpty ? 'No data' : '$pct%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (records.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isLow ? Colors.orangeAccent : Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Present', '$present', Colors.greenAccent),
                _buildMiniStat('Late', '$late', Colors.orangeAccent),
                _buildMiniStat('Absent', '$absent', Colors.redAccent),
                _buildMiniStat('Total', '${records.length}', Colors.white),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTodayMarkButtons() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRecord = _currentAttendance
        .where((a) => a.date == today)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's Class",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              if (todayRecord != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.attendanceColor(
                      todayRecord.status,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    todayRecord.status.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.attendanceColor(todayRecord.status),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMarkButton('present', Icons.check_circle_outline, AppTheme.success),
              const SizedBox(width: 8),
              _buildMarkButton('late', Icons.access_time_outlined, AppTheme.warning),
              const SizedBox(width: 8),
              _buildMarkButton('absent', Icons.cancel_outlined, AppTheme.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkButton(String status, IconData icon, Color color) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _markAttendance(status),
        icon: Icon(icon, size: 16),
        label: Text(status[0].toUpperCase() + status.substring(1)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    final records = List<Attendance>.from(_currentAttendance)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (records.isEmpty) {
      return const EmptyState(
        icon: Icons.event_note_outlined,
        title: 'No records yet',
        subtitle: 'Mark attendance above to get started',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: records.length,
      itemBuilder: (_, i) {
        final a = records[i];
        final color = AppTheme.attendanceColor(a.status);
        final date = DateTime.tryParse(a.date);
        final dateStr = date != null
            ? DateFormat('EEE, d MMM yyyy').format(date)
            : a.date;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(_statusIcon(a.status), color: color, size: 20),
          ),
          title: Text(dateStr),
          subtitle: a.note.isNotEmpty ? Text(a.note) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  a.status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
                iconSize: 20,
                onPressed: () => _deleteRecord(a),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle_outline;
      case 'late':
        return Icons.access_time_outlined;
      case 'absent':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
