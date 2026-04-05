import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import 'add_subject_screen.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    final subjects = await DatabaseHelper.instance.getSubjects();
    setState(() {
      _subjects = subjects;
      _isLoading = false;
    });
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirmed = await showConfirmDelete(
      context,
      title: 'Delete Subject',
      content: 'Delete "${subject.name}"?\nAll related data will be removed.',
    );
    if (confirmed) {
      await DatabaseHelper.instance.deleteSubject(subject.id!);
      _loadSubjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSubjectScreen()),
              );
              _loadSubjects();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
          ? const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              subtitle: 'Tap + to add your first subject',
            )
          : RefreshIndicator(
              onRefresh: _loadSubjects,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  return _SubjectCard(
                    subject: subject,
                    onEdit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddSubjectScreen(subject: subject),
                        ),
                      );
                      _loadSubjects();
                    },
                    onDelete: () => _deleteSubject(subject),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSubjectScreen()),
          );
          _loadSubjects();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── SUBJECT CARD ──────────────────────────────────────────────
class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.fromHex(subject.color);

    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              subject.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            if (subject.code.isNotEmpty) subject.code,
            '${subject.credits} credits',
            if (subject.teacher.isNotEmpty) subject.teacher,
          ].join('  ·  '),
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
      ),
    );
  }
}
