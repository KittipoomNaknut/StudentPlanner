class Attendance {
  final int? id;
  final int subjectId;
  final String date; // 'yyyy-MM-dd'
  final String status; // 'present' | 'absent' | 'late'
  final String note;

  const Attendance({
    this.id,
    required this.subjectId,
    required this.date,
    this.status = 'present',
    this.note = '',
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      date: map['date'] as String,
      status: map['status'] as String? ?? 'present',
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'date': date,
      'status': status,
      'note': note,
    };
  }

  Attendance copyWith({
    int? id,
    int? subjectId,
    String? date,
    String? status,
    String? note,
  }) {
    return Attendance(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isLate => status == 'late';
}
