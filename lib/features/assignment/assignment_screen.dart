import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/assignment.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import 'add_assignment_screen.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});
  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen>
    with SingleTickerProviderStateMixin {
  List<Assignment> _assignments = [];
  List<Subject>    _subjects    = [];
  bool _isLoading   = true;
  String? _filterStatus;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _filterStatus = [null, 'pending', 'done'][_tabCtrl.index];
        });
        _loadData();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      DatabaseHelper.instance.getAssignments(status: _filterStatus),
      DatabaseHelper.instance.getSubjects(),
    ]);
    setState(() {
      _assignments = results[0] as List<Assignment>;
      _subjects    = results[1] as List<Subject>;
      _isLoading   = false;
    });
  }

  Subject? _getSubject(int id) {
    try { return _subjects.firstWhere((s) => s.id == id); }
    catch (_) { return null; }
  }

  Future<void> _toggleStatus(Assignment a) async {
    await DatabaseHelper.instance.updateAssignment(
      a.copyWith(status: a.isDone ? 'pending' : 'done'),
    );
    _loadData();
  }

  Future<void> _delete(Assignment a) async {
    final ok = await showConfirmDelete(context, title: 'Delete Task', content: 'Delete "${a.title}"?');
    if (ok) {
      await DatabaseHelper.instance.deleteAssignment(a.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final overdue = _assignments.where((a) => a.isOverdue).length;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'All'), Tab(text: 'Pending'), Tab(text: 'Done')],
        ),
      ),
      body: Column(
        children: [
          if (overdue > 0) _buildOverdueBanner(overdue),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _assignments.isEmpty
                ? EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: _filterStatus == null ? 'No tasks yet' : 'No ${_filterStatus} tasks',
                    subtitle: 'Tap + to add a task',
                  )
                : _buildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddAssignmentScreen(subjects: _subjects),
          ));
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverdueBanner(int count) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.danger.withValues(alpha: 0.12), AppTheme.orange.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Text(
            '$count overdue task${count > 1 ? 's' : ''} — act now!',
            style: GoogleFonts.nunito(color: AppTheme.danger, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _assignments.length,
        itemBuilder: (_, i) {
          final a       = _assignments[i];
          final subject = _getSubject(a.subjectId);
          return _AssignmentCard(
            assignment: a,
            subject: subject,
            onToggle: () => _toggleStatus(a),
            onEdit: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddAssignmentScreen(subjects: _subjects, assignment: a),
              ));
              _loadData();
            },
            onDelete: () => _delete(a),
          );
        },
      ),
    );
  }
}

// ── CARD ──────────────────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final Subject?   subject;
  final VoidCallback onToggle, onEdit, onDelete;

  const _AssignmentCard({
    required this.assignment, required this.subject,
    required this.onToggle, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subjectColor = subject != null ? AppTheme.fromHex(subject!.color) : Colors.grey;
    final pColor       = AppTheme.priorityColor(assignment.priority);
    final deadlineDate = DateTime.tryParse(assignment.deadline);
    final deadlineStr  = deadlineDate != null
        ? DateFormat('d MMM yyyy').format(deadlineDate)
        : assignment.deadline;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 10, 8, 10),
        child: Row(
          children: [
            // Priority stripe
            Container(
              width: 5, height: 56,
              margin: const EdgeInsets.only(left: 8, right: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.priorityGradient(assignment.priority),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: assignment.isDone ? AppTheme.success : Colors.transparent,
                  border: Border.all(
                    color: assignment.isDone ? AppTheme.success : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: assignment.isDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: assignment.isDone ? TextDecoration.lineThrough : null,
                      color: assignment.isDone ? Colors.grey.shade400 : null,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SubjectDot(color: subjectColor, radius: 4),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          subject?.name ?? '',
                          style: GoogleFonts.nunito(fontSize: 12, color: subjectColor, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 11,
                        color: assignment.isOverdue ? AppTheme.danger : Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        assignment.isOverdue ? 'Overdue · $deadlineStr' : deadlineStr,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: assignment.isOverdue ? AppTheme.danger : Colors.grey.shade400,
                          fontWeight: assignment.isOverdue ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                PriorityBadge(priority: assignment.priority),
                const SizedBox(height: 6),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'delete') onDelete(); },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text('Edit', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                      ])),
                    PopupMenuItem(value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                        const SizedBox(width: 8),
                        Text('Delete', style: GoogleFonts.nunito(color: AppTheme.danger, fontWeight: FontWeight.w600)),
                      ])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
