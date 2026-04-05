import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/grade.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/grade_utils.dart';
import '../../core/widgets/app_widgets.dart';
import 'grade_detail_screen.dart';

class GradeScreen extends StatefulWidget {
  const GradeScreen({super.key});

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  List<Subject> _subjects = [];
  Map<int, List<Grade>> _gradesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;

    // Parallel: load subjects + all grades in one query (no N+1)
    final subjects = await db.getSubjects();
    final subjectIds = subjects.map((s) => s.id!).toList();
    final gradesMap = await db.getGradesForSubjects(subjectIds);

    setState(() {
      _subjects = subjects;
      _gradesMap = gradesMap;
      _isLoading = false;
    });
  }

  double _gpa() => GradeUtils.calculateGPA(_subjects, _gradesMap);

  @override
  Widget build(BuildContext context) {
    final gpa = _gpa();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'GPA Calculator',
            onPressed: _showGPACalculator,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
          ? const EmptyState(
              icon: Icons.grade_outlined,
              title: 'No subjects yet',
              subtitle: 'Add subjects first to track grades',
            )
          : Column(
              children: [
                _buildGPABanner(gpa),
                Expanded(child: _buildSubjectList()),
              ],
            ),
    );
  }

  Widget _buildGPABanner(double gpa) {
    // ignore: unused_local_variable
    final gpaColor = gpa >= 3.0
        ? AppTheme.success
        : gpa >= 2.0
        ? AppTheme.warning
        : AppTheme.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cumulative GPA',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      gpa.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      ' / 4.00',
                      style: TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  '${_subjects.length} subject${_subjects.length != 1 ? 's' : ''} enrolled',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          // GPA ring indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: gpa / 4.0,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    gpa >= 3.0 ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
                Text(
                  _gpaLabel(gpa),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _gpaLabel(double gpa) {
    if (gpa >= 3.5) return 'Excel.';
    if (gpa >= 3.0) return 'Good';
    if (gpa >= 2.0) return 'Fair';
    if (gpa > 0) return 'Low';
    return 'N/A';
  }

  Widget _buildSubjectList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final grades = _gradesMap[subject.id!] ?? [];
          final score = GradeUtils.subjectScore(grades);
          final letter = GradeUtils.letterGrade(score);
          final gp = GradeUtils.gradePoint(letter);
          final subjectColor = AppTheme.fromHex(subject.color);

          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GradeDetailScreen(subject: subject),
                  ),
                );
                _loadData();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Subject color avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: subjectColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${subject.credits} credits  ·  ${grades.length} entries',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          if (grades.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: score / 100,
                                minHeight: 5,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  GradeUtils.gradeColor(score),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (grades.isEmpty)
                      Text('N/A', style: TextStyle(color: Colors.grey.shade400))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${score.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: GradeUtils.gradeColor(score),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'GP ${gp.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGPACalculator() {
    final currentGPA = _gpa();
    final currentCredits = _subjects.fold<int>(0, (sum, s) {
      final grades = _gradesMap[s.id!] ?? [];
      return grades.isNotEmpty ? sum + s.credits : sum;
    });

    final targetCtrl = TextEditingController(text: '3.00');
    final creditsCtrl = TextEditingController(text: '3');

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
          builder: (ctx, setSheet) {
            double? neededGP;
            final target = double.tryParse(targetCtrl.text) ?? 0;
            final credits = int.tryParse(creditsCtrl.text) ?? 3;
            if (target > 0 && target <= 4.0 && credits > 0) {
              neededGP = GradeUtils.gradePointNeeded(
                targetGPA: target,
                currentGPA: currentGPA,
                currentCredits: currentCredits,
                subjectCredits: credits,
              );
            }

            String neededLabel = '';
            Color neededColor = AppTheme.primary;
            if (neededGP != null) {
              if (neededGP <= 0) {
                neededLabel = 'Already achieved!';
                neededColor = AppTheme.success;
              } else if (neededGP > 4.0) {
                neededLabel = 'Not achievable';
                neededColor = AppTheme.danger;
              } else {
                final letter = GradeUtils.letterGrade(neededGP * 25);
                neededLabel =
                    'Need GP ${neededGP.toStringAsFixed(2)} ($letter)';
                neededColor = GradeUtils.gradeColor(neededGP * 25);
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GPA Target Calculator',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current GPA: ${currentGPA.toStringAsFixed(2)}  ·  '
                  '$currentCredits credits tracked',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Target GPA (0–4.0)',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        onChanged: (_) => setSheet(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: creditsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Next subject credits',
                          prefixIcon: Icon(Icons.credit_score_outlined),
                        ),
                        onChanged: (_) => setSheet(() {}),
                      ),
                    ),
                  ],
                ),
                if (neededGP != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: neededColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: neededColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          neededGP <= 0
                              ? Icons.check_circle
                              : neededGP > 4.0
                              ? Icons.cancel
                              : Icons.school,
                          color: neededColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          neededLabel,
                          style: TextStyle(
                            color: neededColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
