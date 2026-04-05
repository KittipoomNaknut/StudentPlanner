import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/grade.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import 'grade_detail_screen.dart';

class GradeScreen extends StatefulWidget {
  const GradeScreen({super.key});

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  List<Subject> _subjects = [];
  Map<int, List<Grade>> _gradesMap = {}; // subjectId → grades
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final subjects = await DatabaseHelper.instance.getSubjects();

    // โหลด grades ของทุกวิชาพร้อมกัน
    final gradesMap = <int, List<Grade>>{};
    for (final s in subjects) {
      gradesMap[s.id!] = await DatabaseHelper.instance.getGrades(s.id!);
    }

    setState(() {
      _subjects = subjects;
      _gradesMap = gradesMap;
      _isLoading = false;
    });
  }

  // คำนวณเกรดของวิชาจากคะแนนทุกตัว
  double _subjectScore(int subjectId) {
    final grades = _gradesMap[subjectId] ?? [];
    if (grades.isEmpty) return 0;
    double totalWeighted = 0;
    double totalWeight = 0;
    for (final g in grades) {
      totalWeighted += g.percentage * g.weight;
      totalWeight += g.weight;
    }
    return totalWeight > 0 ? totalWeighted / totalWeight : 0;
  }

  // แปลง % → เกรด A-F
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

  // แปลงเกรด → grade point
  double _gradePoint(String letter) {
    const map = {
      'A': 4.0,
      'B+': 3.5,
      'B': 3.0,
      'C+': 2.5,
      'C': 2.0,
      'D+': 1.5,
      'D': 1.0,
      'F': 0.0,
    };
    return map[letter] ?? 0.0;
  }

  // คำนวณ GPA รวมทุกวิชา (weighted by credits)
  double _calculateGPA() {
    double totalPoints = 0;
    int totalCredits = 0;
    for (final s in _subjects) {
      final grades = _gradesMap[s.id!] ?? [];
      if (grades.isEmpty) continue;
      final letter = _letterGrade(_subjectScore(s.id!));
      totalPoints += _gradePoint(letter) * s.credits;
      totalCredits += s.credits;
    }
    return totalCredits > 0 ? totalPoints / totalCredits : 0;
  }

  Color _gradeColor(double percent) {
    if (percent >= 70) return AppTheme.success;
    if (percent >= 50) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final gpa = _calculateGPA();

    return Scaffold(
      appBar: AppBar(title: const Text('Grades')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildGPAHeader(gpa),
                Expanded(child: _buildSubjectList()),
              ],
            ),
    );
  }

  // GPA Banner ด้านบน
  Widget _buildGPAHeader(double gpa) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Cumulative GPA',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            gpa.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${_subjects.length} subject${_subjects.length != 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grade_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No subjects yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add subjects first to track grades',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        final score = _subjectScore(subject.id!);
        final letter = _letterGrade(score);
        final grades = _gradesMap[subject.id!] ?? [];

        return Card(
          child: ListTile(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeDetailScreen(subject: subject),
                ),
              );
              _loadData();
            },
            leading: CircleAvatar(
              backgroundColor: AppTheme.fromHex(subject.color),
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            title: Text(
              subject.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${subject.credits} credits  •  ${grades.length} grade entries',
            ),
            trailing: grades.isEmpty
                ? Text('N/A', style: TextStyle(color: Colors.grey.shade400))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _gradeColor(score),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _gradePoint(letter).toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
