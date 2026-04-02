class Assignment {
  final int? id;
  final int subjectId;
  final String title;
  final String description;
  final String deadline; // ISO8601: '2568-03-15'
  final String status; // 'pending' | 'done'
  final String priority; // 'low' | 'medium' | 'high'

  const Assignment({
    this.id,
    required this.subjectId,
    required this.title,
    this.description = '',
    required this.deadline,
    this.status = 'pending',
    this.priority = 'medium',
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      deadline: map['deadline'] as String,
      status: map['status'] as String? ?? 'pending',
      priority: map['priority'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'title': title,
      'description': description,
      'deadline': deadline,
      'status': status,
      'priority': priority,
    };
  }

  Assignment copyWith({
    int? id,
    int? subjectId,
    String? title,
    String? description,
    String? deadline,
    String? status,
    String? priority,
  }) {
    return Assignment(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
    );
  }

  // Computed properties — derive จาก deadline
  bool get isOverdue {
    final d = DateTime.tryParse(deadline);
    return d != null && d.isBefore(DateTime.now()) && status == 'pending';
  }

  bool get isDone => status == 'done';
}
