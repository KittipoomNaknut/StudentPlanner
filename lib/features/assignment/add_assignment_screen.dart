import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/assignment.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../features/notification/notification_service.dart';

class AddAssignmentScreen extends StatefulWidget {
  final List<Subject> subjects;
  final Assignment? assignment;

  const AddAssignmentScreen({
    super.key,
    required this.subjects,
    this.assignment,
  });

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _selectedSubjectId;
  String _priority = 'medium';
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));

  bool get _isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final a = widget.assignment!;
      _titleCtrl.text = a.title;
      _descCtrl.text = a.description;
      _selectedSubjectId = a.subjectId;
      _priority = a.priority;
      _deadline = DateTime.tryParse(a.deadline) ?? _deadline;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final assignment = Assignment(
      id: widget.assignment?.id,
      subjectId: _selectedSubjectId!,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      deadline: DateFormat('yyyy-MM-dd').format(_deadline),
      priority: _priority,
      status: widget.assignment?.status ?? 'pending',
    );

    int savedId;
    if (_isEditing) {
      await DatabaseHelper.instance.updateAssignment(assignment);
      savedId = assignment.id!;
      // ยกเลิก notification เดิมก่อน แล้ว schedule ใหม่
      await NotificationService.instance.cancelAssignmentReminder(savedId);
    } else {
      savedId = await DatabaseHelper.instance.insertAssignment(assignment);
    }

    // Schedule notification สำหรับ assignment ที่ pending
    if (assignment.status == 'pending') {
      final saved = assignment.copyWith(id: savedId);
      await NotificationService.instance.scheduleAssignmentReminder(saved);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Add Task'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Title ────────────────────────────────
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                hintText: 'e.g. Chapter 5 Exercise',
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter task title'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Subject Dropdown ─────────────────────
            DropdownButtonFormField<int>(
              initialValue: _selectedSubjectId,
              decoration: const InputDecoration(
                labelText: 'Subject *',
                prefixIcon: Icon(Icons.book_outlined),
              ),
              items: widget.subjects.map((s) {
                return DropdownMenuItem(
                  value: s.id,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.fromHex(s.color),
                        radius: 8,
                      ),
                      const SizedBox(width: 8),
                      Text(s.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedSubjectId = v),
              validator: (v) => v == null ? 'Please select a subject' : null,
            ),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Additional details...',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // ── Deadline ─────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.grey),
              title: const Text('Deadline'),
              subtitle: Text(
                DateFormat('EEEE, dd MMM yyyy').format(_deadline),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: TextButton(
                onPressed: _pickDeadline,
                child: const Text('Change'),
              ),
            ),
            const Divider(),

            // ── Priority ─────────────────────────────
            const SizedBox(height: 8),
            const Text(
              'Priority',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final isSelected = _priority == p;
                final color = AppTheme.priorityColor(p);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? color : Colors.grey,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // ── Save Button ──────────────────────────
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Update Task' : 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}
