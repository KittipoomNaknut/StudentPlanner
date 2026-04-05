import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/grade.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/grade_utils.dart';
import '../../core/widgets/app_widgets.dart';

class GradeDetailScreen extends StatefulWidget {
  final Subject subject;
  const GradeDetailScreen({super.key, required this.subject});
  @override
  State<GradeDetailScreen> createState() => _GradeDetailScreenState();
}

class _GradeDetailScreenState extends State<GradeDetailScreen> {
  List<Grade> _grades   = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadGrades(); }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    final grades = await DatabaseHelper.instance.getGrades(widget.subject.id!);
    setState(() { _grades = grades; _isLoading = false; });
  }

  double get _totalScore => GradeUtils.subjectScore(_grades);

  void _showAddGradeDialog({Grade? grade}) {
    final nameCtrl     = TextEditingController(text: grade?.name ?? '');
    final scoreCtrl    = TextEditingController(text: grade != null ? grade.score.toString() : '');
    final maxScoreCtrl = TextEditingController(text: grade != null ? grade.maxScore.toString() : '100');
    final weightCtrl   = TextEditingController(text: grade != null ? grade.weight.toString() : '1.0');
    String type = grade?.type ?? 'quiz';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
            Text(grade == null ? 'Add Grade Entry' : 'Edit Grade Entry',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name *', hintText: 'e.g. Midterm Exam',
                prefixIcon: Icon(Icons.edit_rounded))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: scoreCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Score *'))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('/', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.grey.shade400))),
              Expanded(child: TextField(controller: maxScoreCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Max Score'))),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: TextField(controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight'))),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category_rounded)),
              items: ['quiz', 'midterm', 'final', 'project', 'homework'].map((t) =>
                DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)))).toList(),
              onChanged: (v) => setSheet(() => type = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: grade == null ? 'Add Grade' : 'Update Grade',
                gradient: AppTheme.primaryGradient,
                onTap: () async {
                  final name     = nameCtrl.text.trim();
                  final score    = double.tryParse(scoreCtrl.text) ?? 0;
                  final maxScore = double.tryParse(maxScoreCtrl.text) ?? 100;
                  final weight   = double.tryParse(weightCtrl.text) ?? 1.0;
                  if (name.isEmpty) return;
                  final newGrade = Grade(id: grade?.id, subjectId: widget.subject.id!,
                    name: name, score: score, maxScore: maxScore, weight: weight, type: type);
                  if (grade == null) await DatabaseHelper.instance.insertGrade(newGrade);
                  else               await DatabaseHelper.instance.updateGrade(newGrade);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadGrades();
                },
              ),
            ),
          ],
        )),
      ),
    );
  }

  Future<void> _deleteGrade(Grade g) async {
    final ok = await showConfirmDelete(context, title: 'Delete Grade', content: 'Delete "${g.name}"?');
    if (ok) { await DatabaseHelper.instance.deleteGrade(g.id!); _loadGrades(); }
  }

  @override
  Widget build(BuildContext context) {
    final color  = AppTheme.fromHex(widget.subject.color);
    final score  = _totalScore;
    final letter = GradeUtils.letterGrade(score);
    final gp     = GradeUtils.gradePoint(letter);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: color,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddGradeDialog())],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              _buildHeader(color, score, letter, gp),
              Expanded(child: _grades.isEmpty
                ? const EmptyState(icon: Icons.grading_rounded, title: 'No grade entries yet', subtitle: 'Tap + to add a grade')
                : _buildGradeList(color)),
            ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGradeDialog(),
        backgroundColor: color,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(Color color, double score, String letter, double gp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Score', '${score.toStringAsFixed(1)}%'),
          _vDivider(),
          _stat('Grade', letter),
          _vDivider(),
          _stat('GP', gp.toStringAsFixed(1)),
          _vDivider(),
          _stat('Credits', '${widget.subject.credits}'),
          _vDivider(),
          _stat('Entries', '${_grades.length}'),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 32, color: Colors.white24);

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
    Text(label, style: GoogleFonts.nunito(color: Colors.white70, fontSize: 13)),
  ]);

  Widget _buildGradeList(Color subjectColor) {
    final grouped = <String, List<Grade>>{};
    for (final g in _grades) grouped.putIfAbsent(g.type, () => []).add(g);
    const order = ['midterm', 'final', 'project', 'quiz', 'homework'];
    final types = grouped.keys.toList()..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        for (final type in types) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: subjectColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(type[0].toUpperCase() + type.substring(1),
                  style: GoogleFonts.nunito(color: subjectColor, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ),
          ...grouped[type]!.map((g) => _buildGradeCard(g, subjectColor)),
        ],
      ],
    );
  }

  Widget _buildGradeCard(Grade g, Color subjectColor) {
    final pct      = g.percentage;
    final pctColor = GradeUtils.gradeColor(pct);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.name, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${g.score} / ${g.maxScore}${g.weight != 1.0 ? '  ·  ×${g.weight}' : ''}',
                style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100, minHeight: 5,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${pct.toStringAsFixed(1)}%',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: pctColor, fontSize: 16)),
            Text(GradeUtils.letterGrade(pct),
              style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13)),
          ]),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade300, size: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) { if (v == 'edit') _showAddGradeDialog(grade: g); if (v == 'delete') _deleteGrade(g); },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text('Edit', style: GoogleFonts.nunito())),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: GoogleFonts.nunito(color: Colors.red))),
            ],
          ),
        ]),
      ),
    );
  }
}
