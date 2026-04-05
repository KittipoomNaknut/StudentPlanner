import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/grade.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';

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

  // คำนวณคะแนนรวม weighted
  double get _totalScore {
    if (_grades.isEmpty) return 0;
    double totalWeighted = 0;
    double totalWeight = 0;
    for (final g in _grades) {
      totalWeighted += g.percentage * g.weight;
      totalWeight += g.weight;
    }
    return totalWeight > 0 ? totalWeighted / totalWeight : 0;
  }

  String _letterGrade(double percent) {
    if (percent >= 80) return 'A';
    if (percent >= 75) return 'B+';
    if (percent >= 70) return 'B';
    if (percent >= 65) return 'C+';
    if (percent >= 60) return 'C';
    if (percent >= 55) return 'D+';
    if (percent >= 50) return 'D';
    return 'F';
  }

  void _showAddGradeDialog({Grade? grade}) {
    final nameCtrl = TextEditingController(text: grade?.name ?? '');
    final scoreCtrl = TextEditingController(
      text: grade != null ? grade.score.toString() : '',
    );
    final maxScoreCtrl = TextEditingController(
      text: grade != null ? grade.maxScore.toString() : '100',
    );
    String type = grade?.type ?? 'quiz';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(grade == null ? 'Add Grade Entry' : 'Edit Grade Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g. Midterm Exam',
                  ),
                ),
                const SizedBox(height: 12),

                // Score / MaxScore
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: scoreCtrl,
                        keyboardType: TextInputType.number,
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
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Score',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Type dropdown
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['quiz', 'midterm', 'final', 'project', 'homework']
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final score = double.tryParse(scoreCtrl.text) ?? 0;
                final maxScore = double.tryParse(maxScoreCtrl.text) ?? 100;

                if (name.isEmpty) return;

                final newGrade = Grade(
                  id: grade?.id,
                  subjectId: widget.subject.id!,
                  name: name,
                  score: score,
                  maxScore: maxScore,
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
              child: Text(grade == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGrade(Grade grade) async {
    await DatabaseHelper.instance.deleteGrade(grade.id!);
    _loadGrades();
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = AppTheme.fromHex(widget.subject.color);
    final score = _totalScore;
    final letter = _letterGrade(score);

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
                // Score Summary Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: subjectColor.withValues(alpha: 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Score', '${score.toStringAsFixed(1)}%'),
                      _buildStat('Grade', letter),
                      _buildStat('Credits', '${widget.subject.credits}'),
                      _buildStat('Entries', '${_grades.length}'),
                    ],
                  ),
                ),

                // Grade List
                Expanded(
                  child: _grades.isEmpty
                      ? Center(
                          child: Text(
                            'No grade entries yet',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _grades.length,
                          itemBuilder: (context, index) {
                            final g = _grades[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: subjectColor.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  g.type.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: subjectColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                g.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${g.type.toUpperCase()}  •  '
                                '${g.score}/${g.maxScore}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${g.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: g.percentage >= 70
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'edit')
                                        _showAddGradeDialog(grade: g);
                                      if (val == 'delete') _deleteGrade(g);
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGradeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}
