import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  void initState() { super.initState(); _loadSubjects(); }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    final subjects = await DatabaseHelper.instance.getSubjects();
    setState(() { _subjects = subjects; _isLoading = false; });
  }

  Future<void> _delete(Subject s) async {
    final ok = await showConfirmDelete(context,
      title: 'Delete Subject',
      content: 'Delete "${s.name}"?\nAll related data will be removed.');
    if (ok) { await DatabaseHelper.instance.deleteSubject(s.id!); _loadSubjects(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Subjects'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubjectScreen()));
          _loadSubjects();
        }),
      ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
          ? const EmptyState(icon: Icons.menu_book_rounded, title: 'No subjects yet',
              subtitle: 'Tap + to add your first subject')
          : RefreshIndicator(
              onRefresh: _loadSubjects,
              color: AppTheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _subjects.length,
                itemBuilder: (_, i) {
                  final s = _subjects[i];
                  return _SubjectCard(subject: s,
                    onEdit: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddSubjectScreen(subject: s)));
                      _loadSubjects();
                    },
                    onDelete: () => _delete(s));
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubjectScreen()));
          _loadSubjects();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onEdit, onDelete;
  const _SubjectCard({required this.subject, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.fromHex(subject.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.subjectGradient(subject.color),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(
                  subject.name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subject.name, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  [
                    if (subject.code.isNotEmpty) subject.code,
                    '${subject.credits} credits',
                    if (subject.teacher.isNotEmpty) subject.teacher,
                  ].join('  ·  '),
                  style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 12),
                ),
              ])),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'delete') onDelete(); },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text('Edit', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                  ])),
                  PopupMenuItem(value: 'delete', child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                    const SizedBox(width: 8),
                    Text('Delete', style: GoogleFonts.nunito(color: AppTheme.danger, fontWeight: FontWeight.w600)),
                  ])),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
