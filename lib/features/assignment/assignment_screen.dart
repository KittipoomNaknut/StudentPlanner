import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/assignment.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
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
  String? _filterStatus; // null = all, 'pending', 'done'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final assignments = await DatabaseHelper.instance.getAssignments(
      status: _filterStatus,
    );
    final subjects = await DatabaseHelper.instance.getSubjects();
    setState(() {
      _assignments = assignments;
      _subjects = subjects;
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${a.title}"?'),
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
      await DatabaseHelper.instance.deleteAssignment(a.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          // Filter button
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list,
              color: _filterStatus != null ? Colors.orange : Colors.white,
            ),
            onSelected: (val) {
              setState(() => _filterStatus = val);
              _loadData();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'done', child: Text('Done')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
          ? _buildEmptyState()
          : _buildList(),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus == null
                ? 'No tasks yet'
                : 'No ${_filterStatus} tasks',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a task',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
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
    );
  }
}

// ── ASSIGNMENT CARD ──────────────────────────────────────
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
        ? DateFormat('dd MMM yyyy').format(deadlineDate)
        : assignment.deadline;

    return Card(
      child: ListTile(
        // Checkbox ซ้าย
        leading: GestureDetector(
          onTap: onToggle,
          child: CircleAvatar(
            backgroundColor: assignment.isDone
                ? Colors.green.shade100
                : AppTheme.priorityColor(
                    assignment.priority,
                  ).withValues(alpha: 0.15),
            child: Icon(
              assignment.isDone
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: assignment.isDone
                  ? Colors.green
                  : AppTheme.priorityColor(assignment.priority),
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
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subject != null)
              Row(
                children: [
                  CircleAvatar(backgroundColor: subjectColor, radius: 5),
                  const SizedBox(width: 6),
                  Text(subject!.name, style: const TextStyle(fontSize: 12)),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: assignment.isOverdue ? AppTheme.danger : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  assignment.isOverdue ? 'Overdue · $deadlineStr' : deadlineStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: assignment.isOverdue ? AppTheme.danger : Colors.grey,
                    fontWeight: assignment.isOverdue ? FontWeight.bold : null,
                  ),
                ),
                const SizedBox(width: 8),
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.priorityColor(
                      assignment.priority,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    assignment.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.priorityColor(assignment.priority),
                    ),
                  ),
                ),
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
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),

        isThreeLine: true,
      ),
    );
  }
}
