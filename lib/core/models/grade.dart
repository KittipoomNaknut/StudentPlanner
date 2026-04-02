class Grade {
  final int? id;
  final int subjectId;
  final String name;
  final double score;
  final double maxScore;
  final double weight;
  final String type; // 'midterm' | 'final' | 'quiz' | 'project'

  const Grade({
    this.id,
    required this.subjectId,
    required this.name,
    required this.score,
    required this.maxScore,
    this.weight = 1.0,
    this.type = 'quiz',
  });

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      name: map['name'] as String,
      score: (map['score'] as num).toDouble(),
      maxScore: (map['max_score'] as num).toDouble(),
      weight: (map['weight'] as num?)?.toDouble() ?? 1.0,
      type: map['type'] as String? ?? 'quiz',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'name': name,
      'score': score,
      'max_score': maxScore,
      'weight': weight,
      'type': type,
    };
  }

  Grade copyWith({
    int? id,
    int? subjectId,
    String? name,
    double? score,
    double? maxScore,
    double? weight,
    String? type,
  }) {
    return Grade(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      weight: weight ?? this.weight,
      type: type ?? this.type,
    );
  }

  // คะแนนเป็น % weighted
  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
}
