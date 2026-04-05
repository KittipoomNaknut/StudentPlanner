import 'package:flutter/material.dart';
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

class _AssignmentScreenState extends State<AssignmentScreen> {
  List<Assignment> _assignments = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      DatabaseHelper.instance.getAssignments(status: _filterStatus),
      DatabaseHelper.instance.getSubjects(),
    ]);
    setState(() {
      _assignments = results[0] as List<Assignment>;
      _subjects = results[1] as List<Subject>;
      _isLoading = false;
    });
  }

  Subject? _getSubject(int subjectId) {
    try {
      return _subjects.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleStatus(Assignment a) async {
    final updated = a.copyWith(status: a.isDone ? 'pending' : 'done');
    await DatabaseHelper.instance.updateAssignment(updated);
    _loadData();
  }

  Future<void> _delete(Assignment a) async {
    final confirmed = await showConfirmDelete(
      context,
      title: 'Delete Task',
      content: 'Delete "${a.title}"?',
    );
    if (confirmed) {
      await DatabaseHelper.instance.deleteAssignment(a.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final overdue = _assignments.where((a) => a.isOverdue).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list,
              color: _filterStatus != null ? Colors.orange : Colors.white,
            ),
            tooltip: 'Filter',
            onSelected: (val) {
              setState(() => _filterStatus = val);
              _loadData();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      size: 18,
                      color: _filterStatus == null ? AppTheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('All'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 18,
                      color: _filterStatus == 'pending'
                          ? AppTheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Pending'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'done',
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: _filterStatus == 'done' ? AppTheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Done'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (overdue > 0) _buildOverdueBanner(overdue),
                Expanded(
                  child: _assignments.isEmpty
                      ? EmptyState(
                          icon: Icons.assignment_outlined,
                          title: _filterStatus == null
                              ? 'No tasks yet'
                              : 'No $_filterStatus tasks',
                          subtitle: 'Tap + to add a task',
                        )
                      : _buildList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddAssignmentScreen(subjects: _subjects),
            ),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverdueBanner(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.danger.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Text(
            '$count overdue task${count > 1 ? 's' : ''}',
            style: const TextStyle(
              color: AppTheme.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final a = _assignments[index];
          final subject = _getSubject(a.subjectId);
          return _AssignmentCard(
            assignment: a,
            subject: subject,
            onToggle: () => _toggleStatus(a),
            onEdit: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddAssignmentScreen(subjects: _subjects, assignment: a),
                ),
              );
              _loadData();
            },
            onDelete: () => _delete(a),
          );
        },
      ),
    );
  }
}

// ── ASSIGNMENT CARD ──────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final Subject? subject;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentCard({
    required this.assignment,
    required this.subject,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subjectColor = subject != null
        ? AppTheme.fromHex(subject!.color)
        : Colors.grey;
    final deadlineDate = DateTime.tryParse(assignment.deadline);
    final deadlineStr = deadlineDate != null
        ? DateFormat('d MMM yyyy').format(deadlineDate)
        : assignment.deadline;
    final priorityColor = AppTheme.priorityColor(assignment.priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                key: ValueKey(assignment.isDone),
                backgroundColor: assignment.isDone
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : priorityColor.withValues(alpha: 0.12),
                child: Icon(
                  assignment.isDone
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: assignment.isDone ? AppTheme.success : priorityColor,
                  size: 22,
                ),
              ),
            ),
          ),
          title: Text(
            assignment.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: assignment.isDone ? TextDecoration.lineThrough : null,
              color: assignment.isDone ? Colors.grey : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subject != null)
                Row(
                  children: [
                    SubjectDot(color: subjectColor, radius: 4),
                    const SizedBox(width: 5),
                    Text(
                      subject!.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: subjectColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 11,
                    color: assignment.isOverdue ? AppTheme.danger : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    assignment.isOverdue
                        ? 'Overdue · $deadlineStr'
                        : deadlineStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: assignment.isOverdue
                          ? AppTheme.danger
                          : Colors.grey,
                      fontWeight: assignment.isOverdue
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: assignment.priority),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}
