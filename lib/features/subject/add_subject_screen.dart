import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/subject.dart';

class AddSubjectScreen extends StatefulWidget {
  final Subject? subject; // null = Add, มีค่า = Edit

  const AddSubjectScreen({super.key, this.subject});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  int _credits = 3;
  Color _color = const Color(0xFF1565C0);

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    // ถ้าเป็น Edit — ใส่ค่าเดิมลงใน form
    if (_isEditing) {
      final s = widget.subject!;
      _nameCtrl.text = s.name;
      _codeCtrl.text = s.code;
      _teacherCtrl.text = s.teacher;
      _credits = s.credits;
      _color = Color(
        int.parse('FF${s.color.replaceFirst('#', '')}', radix: 16),
      );
    }
  }

  @override
  void dispose() {
    // ต้อง dispose controller ทุกตัวเสมอ ป้องกัน memory leak
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _teacherCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final colorHex =
        '#${_color.value.toRadixString(16).substring(2).toUpperCase()}';

    final subject = Subject(
      id: widget.subject?.id,
      name: _nameCtrl.text.trim(),
      code: _codeCtrl.text.trim(),
      color: colorHex,
      teacher: _teacherCtrl.text.trim(),
      credits: _credits,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateSubject(subject);
    } else {
      await DatabaseHelper.instance.insertSubject(subject);
    }

    if (mounted) Navigator.pop(context);
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick Subject Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _color,
            onColorChanged: (c) => setState(() => _color = c),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Subject' : 'Add Subject'),
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
            // ── Subject Name ────────────────────────
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject Name *',
                hintText: 'e.g. Calculus I',
                prefixIcon: Icon(Icons.book_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter subject name'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Subject Code ────────────────────────
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject Code',
                hintText: 'e.g. MTH101',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),

            // ── Teacher ─────────────────────────────
            TextFormField(
              controller: _teacherCtrl,
              decoration: const InputDecoration(
                labelText: 'Teacher',
                hintText: 'e.g. Dr. Smith',
                prefixIcon: Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ── Credits ─────────────────────────────
            Row(
              children: [
                const Icon(Icons.star_outline, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('Credits'),
                const Spacer(),
                // ปุ่ม - / ตัวเลข / ปุ่ม +
                IconButton(
                  onPressed: () => setState(() {
                    if (_credits > 1) _credits--;
                  }),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_credits',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    if (_credits < 9) _credits++;
                  }),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const Divider(),

            // ── Color Picker ────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_outlined, color: Colors.grey),
              title: const Text('Subject Color'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(backgroundColor: _color, radius: 16),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _pickColor,
            ),
            const Divider(),

            const SizedBox(height: 24),

            // ── Save Button ─────────────────────────
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Update Subject' : 'Add Subject'),
            ),
          ],
        ),
      ),
    );
  }
}
