import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/note.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note; // null = new note
  final List<Subject> subjects;

  const NoteDetailScreen({super.key, this.note, required this.subjects});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  int? _selectedSubjectId;
  bool _hasChanges = false;
  bool _isSaving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final n = widget.note!;
      _titleCtrl.text = n.title;
      _contentCtrl.text = n.content;
      _selectedSubjectId = n.subjectId;
    } else if (widget.subjects.isNotEmpty) {
      // default เลือกวิชาแรก
      _selectedSubjectId = widget.subjects.first.id;
    }

    // ติดตามการเปลี่ยนแปลง
    _titleCtrl.addListener(() => setState(() => _hasChanges = true));
    _contentCtrl.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return false;
    }
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return false;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    final note = Note(
      id: widget.note?.id,
      subjectId: _selectedSubjectId!,
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      updatedAt: now,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateNote(note);
    } else {
      await DatabaseHelper.instance.insertNote(note);
    }

    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });
    return true;
  }

  // เมื่อกด back — ถามว่าจะบันทึกไหมถ้ามีการเปลี่ยนแปลง
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      final saved = await _save();
      return saved;
    }
    return result == 'discard';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Note' : 'New Note'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () async {
                  final saved = await _save();
                  if (saved && context.mounted) Navigator.pop(context);
                },
                child: Text(
                  _hasChanges ? 'Save *' : 'Save',
                  style: TextStyle(
                    color: _hasChanges ? Colors.orange.shade200 : Colors.white,
                    fontWeight: _hasChanges
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Subject Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedSubjectId,
                  isExpanded: true,
                  hint: const Text('Select subject'),
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
                  onChanged: (v) => setState(() {
                    _selectedSubjectId = v;
                    _hasChanges = true;
                  }),
                ),
              ),
            ),

            // Title Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _titleCtrl,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 1,
              ),
            ),

            // Updated at
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Last updated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.tryParse(widget.note!.updatedAt) ?? DateTime.now())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),

            const Divider(height: 16),

            // Content Field — ขยายเต็มพื้นที่
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _contentCtrl,
                  style: const TextStyle(fontSize: 16, height: 1.7),
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null, // ขยายได้ไม่จำกัดบรรทัด
                  expands: true, // เต็มพื้นที่ใน Expanded
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
