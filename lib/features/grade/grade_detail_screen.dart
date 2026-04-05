import 'package:flutter/material.dart';
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
  List<Grade> _grades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    final grades = await DatabaseHelper.instance.getGrades(widget.subject.id!);
    setState(() {
      _grades = grades;
      _isLoading = false;
    });
  }

  double get _totalScore => GradeUtils.subjectScore(_grades);

  void _showAddGradeDialog({Grade? grade}) {
    final nameCtrl = TextEditingController(text: grade?.name ?? '');
    final scoreCtrl = TextEditingController(
      text: grade != null ? grade.score.toString() : '',
    );
    final maxScoreCtrl = TextEditingController(
      text: grade != null ? grade.maxScore.toString() : '100',
    );
    final weightCtrl = TextEditingController(
      text: grade != null ? grade.weight.toString() : '1.0',
    );
    String type = grade?.type ?? 'quiz';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                grade == null ? 'Add Grade Entry' : 'Edit Grade Entry',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'e.g. Midterm Exam',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: scoreCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Score *'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('/', style: TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: maxScoreCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Max Score'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Weight'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ['quiz', 'midterm', 'final', 'project', 'homework']
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheet(() => type = v!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final score = double.tryParse(scoreCtrl.text) ?? 0;
                    final maxScore = double.tryParse(maxScoreCtrl.text) ?? 100;
                    final weight = double.tryParse(weightCtrl.text) ?? 1.0;
                    if (name.isEmpty) return;

                    final newGrade = Grade(
                      id: grade?.id,
                      subjectId: widget.subject.id!,
                      name: name,
                      score: score,
                      maxScore: maxScore,
                      weight: weight,
                      type: type,
                    );

                    if (grade == null) {
                      await DatabaseHelper.instance.insertGrade(newGrade);
                    } else {
                      await DatabaseHelper.instance.updateGrade(newGrade);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadGrades();
                  },
                  child: Text(grade == null ? 'Add Grade' : 'Update Grade'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteGrade(Grade grade) async {
    final confirmed = await showConfirmDelete(
      context,
      title: 'Delete Grade',
      content: 'Delete "${grade.name}"?',
    );
    if (confirmed) {
      await DatabaseHelper.instance.deleteGrade(grade.id!);
      _loadGrades();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = AppTheme.fromHex(widget.subject.color);
    final score = _totalScore;
    final letter = GradeUtils.letterGrade(score);
    final gp = GradeUtils.gradePoint(letter);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGradeDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(subjectColor, score, letter, gp),
                Expanded(
                  child: _grades.isEmpty
                      ? const EmptyState(
                          icon: Icons.grading_outlined,
                          title: 'No grade entries yet',
                          subtitle: 'Tap + to add a grade',
                        )
                      : _buildGradeList(subjectColor),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGradeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(Color color, double score, String letter, double gp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Score', '${score.toStringAsFixed(1)}%'),
          _buildDivider(),
          _buildStat('Grade', letter),
          _buildDivider(),
          _buildStat('GP', gp.toStringAsFixed(1)),
          _buildDivider(),
          _buildStat('Credits', '${widget.subject.credits}'),
          _buildDivider(),
          _buildStat('Entries', '${_grades.length}'),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Container(width: 1, height: 30, color: Colors.white24);

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildGradeList(Color subjectColor) {
    // Group by type
    final grouped = <String, List<Grade>>{};
    for (final g in _grades) {
      grouped.putIfAbsent(g.type, () => []).add(g);
    }
    final order = ['midterm', 'final', 'project', 'quiz', 'homework'];
    final sortedTypes = grouped.keys.toList()
      ..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        for (final type in sortedTypes) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              type[0].toUpperCase() + type.substring(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: subjectColor,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...grouped[type]!.map((g) => _buildGradeCard(g, subjectColor)),
        ],
      ],
    );
  }

  Widget _buildGradeCard(Grade g, Color subjectColor) {
    final pct = g.percentage;
    final pctColor = GradeUtils.gradeColor(pct);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${g.score} / ${g.maxScore}'
                    '${g.weight != 1.0 ? '  ·  weight ${g.weight}' : ''}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: pctColor,
                    fontSize: 16,
                  ),
                ),
                Text(
                  GradeUtils.letterGrade(pct),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _showAddGradeDialog(grade: g);
                if (val == 'delete') _deleteGrade(g);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
