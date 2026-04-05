import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/schedule.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AddScheduleScreen extends StatefulWidget {
  final List<Subject> subjects;
  final Schedule? schedule;
  final String initialType;

  const AddScheduleScreen({
    super.key,
    required this.subjects,
    this.schedule,
    this.initialType = 'class',
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomCtrl = TextEditingController();

  int? _selectedSubjectId;
  String _type = 'class';
  int _dayOfWeek = 0;
  String _startTime = '09:00';
  String _endTime = '12:00';
  String _examDate = '';

  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (_isEditing) {
      final s = widget.schedule!;
      _selectedSubjectId = s.subjectId;
      _type = s.type;
      _dayOfWeek = s.dayOfWeek ?? 0;
      _startTime = s.startTime;
      _endTime = s.endTime;
      _roomCtrl.text = s.room;
      _examDate = s.date ?? '';
    }
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final parts = (isStart ? _startTime : _endTime).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final str =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart)
          _startTime = str;
        else
          _endTime = str;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(
        () => _examDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'exam' && _examDate.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select exam date')));
      return;
    }

    final schedule = Schedule(
      id: widget.schedule?.id,
      subjectId: _selectedSubjectId!,
      type: _type,
      dayOfWeek: _type == 'class' ? _dayOfWeek : null,
      date: _type == 'exam' ? _examDate : null,
      startTime: _startTime,
      endTime: _endTime,
      room: _roomCtrl.text.trim(),
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateSchedule(schedule);
    } else {
      await DatabaseHelper.instance.insertSchedule(schedule);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Schedule' : 'Add Schedule'),
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
            // ── Type Toggle ──────────────────────────
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'class',
                  label: Text('Class'),
                  icon: Icon(Icons.class_outlined),
                ),
                ButtonSegment(
                  value: 'exam',
                  label: Text('Exam'),
                  icon: Icon(Icons.event_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            // ── Subject ──────────────────────────────
            DropdownButtonFormField<int>(
              value: _selectedSubjectId,
              decoration: const InputDecoration(
                labelText: 'Subject *',
                prefixIcon: Icon(Icons.book_outlined),
              ),
              items: widget.subjects
                  .map(
                    (s) => DropdownMenuItem(
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
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubjectId = v),
              validator: (v) => v == null ? 'Please select a subject' : null,
            ),
            const SizedBox(height: 16),

            // ── Day of Week (class only) ──────────────
            if (_type == 'class') ...[
              const Text(
                'Day of Week',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final selected = _dayOfWeek == i;
                  return ChoiceChip(
                    label: Text(AppConstants.days[i]),
                    selected: selected,
                    onSelected: (_) => setState(() => _dayOfWeek = i),
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],

            // ── Exam Date (exam only) ─────────────────
            if (_type == 'exam') ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Colors.grey),
                title: const Text('Exam Date *'),
                subtitle: Text(
                  _examDate.isEmpty ? 'Not selected' : _examDate,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _examDate.isEmpty ? Colors.red : null,
                  ),
                ),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Select'),
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // ── Time ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: Colors.grey),
                    title: const Text('Start', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      _startTime,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const Text(
                  '→',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.access_time_filled,
                      color: Colors.grey,
                    ),
                    title: const Text('End', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      _endTime,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const Divider(),

            // ── Room ─────────────────────────────────
            TextFormField(
              controller: _roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Room',
                hintText: 'e.g. SC-101',
                prefixIcon: Icon(Icons.room_outlined),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Update Schedule' : 'Add Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
