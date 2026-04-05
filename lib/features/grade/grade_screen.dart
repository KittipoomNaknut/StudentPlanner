import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<Subject>          _subjects  = [];
  Map<int, List<Grade>>  _gradesMap = {};
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final subjects   = await DatabaseHelper.instance.getSubjects();
    final gradesMap  = await DatabaseHelper.instance.getGradesForSubjects(
      subjects.map((s) => s.id!).toList(),
    );
    setState(() { _subjects = subjects; _gradesMap = gradesMap; _isLoading = false; });
  }

  double _gpa() => GradeUtils.calculateGPA(_subjects, _gradesMap);

  @override
  Widget build(BuildContext context) {
    final gpa = _gpa();
    return Scaffold(
      backgroundColor: AppTheme.background,
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
          ? const EmptyState(icon: Icons.bar_chart_rounded, title: 'No subjects yet', subtitle: 'Add subjects first to track grades')
          : Column(children: [
              _buildGPABanner(gpa),
              Expanded(child: _buildList()),
            ]),
    );
  }

  Widget _buildGPABanner(double gpa) {
    final label  = gpa >= 3.5 ? 'Excellent ✨' : gpa >= 3.0 ? 'Good 👍' : gpa >= 2.0 ? 'Fair 📚' : gpa > 0 ? 'Needs Work 💪' : 'No Data';
    final pct    = (gpa / 4.0).clamp(0.0, 1.0);

    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 190,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Stack(
          children: [
            // Background circles
            Positioned(top: -20, right: -20,
              child: Container(width: 130, height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Row(
                children: [
                  // GPA ring
                  SizedBox(
                    width: 110, height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(gpa.toStringAsFixed(2),
                              style: GoogleFonts.nunito(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                            Text('/ 4.00', style: GoogleFonts.nunito(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cumulative GPA', style: GoogleFonts.nunito(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(label, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                        const SizedBox(height: 8),
                        Text('${_subjects.length} subject${_subjects.length != 1 ? 's' : ''} enrolled',
                          style: GoogleFonts.nunito(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _subjects.length,
        itemBuilder: (_, i) {
          final subject = _subjects[i];
          final grades  = _gradesMap[subject.id!] ?? [];
          final score   = GradeUtils.subjectScore(grades);
          final letter  = GradeUtils.letterGrade(score);
          final gp      = GradeUtils.gradePoint(letter);
          final color   = AppTheme.fromHex(subject.color);

          return GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => GradeDetailScreen(subject: subject),
              ));
              _loadData();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  // Color top bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: AppTheme.subjectGradient(subject.color),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(letter,
                              style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subject.name, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text('${subject.credits} credits  ·  ${grades.length} entries',
                                style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 12)),
                              if (grades.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: score / 100,
                                    minHeight: 5,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(GradeUtils.gradeColor(score)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        grades.isEmpty
                            ? Text('N/A', style: GoogleFonts.nunito(color: Colors.grey.shade300, fontWeight: FontWeight.w700))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${score.toStringAsFixed(1)}%',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                      color: GradeUtils.gradeColor(score),
                                      fontSize: 16,
                                    )),
                                  Text('GP ${gp.toStringAsFixed(1)}',
                                    style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 12)),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGPACalculator() {
    final currentGPA     = _gpa();
    final currentCredits = _subjects.fold<int>(0, (sum, s) =>
      (_gradesMap[s.id!] ?? []).isNotEmpty ? sum + s.credits : sum);
    final targetCtrl  = TextEditingController(text: '3.00');
    final creditsCtrl = TextEditingController(text: '3');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(builder: (ctx, setSheet) {
          final target  = double.tryParse(targetCtrl.text) ?? 0;
          final credits = int.tryParse(creditsCtrl.text) ?? 3;
          double? neededGP;
          if (target > 0 && target <= 4.0 && credits > 0) {
            neededGP = GradeUtils.gradePointNeeded(
              targetGPA: target, currentGPA: currentGPA,
              currentCredits: currentCredits, subjectCredits: credits,
            );
          }

          String label = ''; Color labelColor = AppTheme.primary;
          if (neededGP != null) {
            if (neededGP <= 0) { label = 'Already achieved! 🎉'; labelColor = AppTheme.success; }
            else if (neededGP > 4.0) { label = 'Not achievable this semester 😓'; labelColor = AppTheme.danger; }
            else {
              final letter = GradeUtils.letterGrade(neededGP * 25);
              label = 'Need GP ${neededGP.toStringAsFixed(2)} ($letter) 🎯';
              labelColor = GradeUtils.gradeColor(neededGP * 25);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GPA Calculator', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Current GPA: ${currentGPA.toStringAsFixed(2)}  ·  $currentCredits credits',
                        style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: targetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Target GPA (0–4.0)', prefixIcon: Icon(Icons.flag_rounded)),
                    onChanged: (_) => setSheet(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: creditsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Subject credits', prefixIcon: Icon(Icons.credit_score_rounded)),
                    onChanged: (_) => setSheet(() {}),
                  ),
                ),
              ]),
              if (neededGP != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: labelColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: labelColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    Icon(neededGP <= 0 ? Icons.check_circle_rounded : neededGP > 4.0 ? Icons.cancel_rounded : Icons.school_rounded,
                      color: labelColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label, style: GoogleFonts.nunito(color: labelColor, fontWeight: FontWeight.w700, fontSize: 15))),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
            ],
          );
        }),
      ),
    );
  }
}
