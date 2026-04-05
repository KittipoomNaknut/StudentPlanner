import 'package:flutter/material.dart';
import '../models/grade.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class GradeUtils {
  GradeUtils._();

  static String letterGrade(double percent) {
    if (percent >= 80) return 'A';
    if (percent >= 75) return 'B+';
    if (percent >= 70) return 'B';
    if (percent >= 65) return 'C+';
    if (percent >= 60) return 'C';
    if (percent >= 55) return 'D+';
    if (percent >= 50) return 'D';
    return 'F';
  }

  static double gradePoint(String letter) {
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

  static double subjectScore(List<Grade> grades) {
    if (grades.isEmpty) return 0;
    double totalWeighted = 0, totalWeight = 0;
    for (final g in grades) {
      totalWeighted += g.percentage * g.weight;
      totalWeight += g.weight;
    }
    return totalWeight > 0 ? totalWeighted / totalWeight : 0;
  }

  static double calculateGPA(
    List<Subject> subjects,
    Map<int, List<Grade>> gradesMap,
  ) {
    double totalPoints = 0;
    int totalCredits = 0;
    for (final s in subjects) {
      final grades = gradesMap[s.id!] ?? [];
      if (grades.isEmpty) continue;
      final letter = letterGrade(subjectScore(grades));
      totalPoints += gradePoint(letter) * s.credits;
      totalCredits += s.credits;
    }
    return totalCredits > 0 ? totalPoints / totalCredits : 0;
  }

  static Color gradeColor(double percent) {
    if (percent >= 70) return AppTheme.success;
    if (percent >= 50) return AppTheme.warning;
    return AppTheme.danger;
  }

  /// Returns the grade point needed per credit to hit [targetGPA]
  /// given current weighted points and credits.
  static double? gradePointNeeded({
    required double targetGPA,
    required double currentGPA,
    required int currentCredits,
    required int subjectCredits,
  }) {
    if (subjectCredits <= 0) return null;
    final currentPoints = currentGPA * currentCredits;
    final totalCredits = currentCredits + subjectCredits;
    final needed = (targetGPA * totalCredits - currentPoints) / subjectCredits;
    return needed.clamp(0.0, 4.0);
  }
}
