class Schedule {
  final int? id;
  final int subjectId;
  final String type; // 'class' | 'exam'
  final int? dayOfWeek; // 0=จันทร์ ... 6=อาทิตย์ (สำหรับ class)
  final String? date; // ISO8601 (สำหรับ exam)
  final String startTime; // 'HH:mm'
  final String endTime;
  final String room;

  const Schedule({
    this.id,
    required this.subjectId,
    required this.type,
    this.dayOfWeek,
    this.date,
    required this.startTime,
    required this.endTime,
    this.room = '',
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      type: map['type'] as String,
      dayOfWeek: map['day_of_week'] as int?,
      date: map['date'] as String?,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      room: map['room'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'type': type,
      'day_of_week': dayOfWeek,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
    };
  }

  Schedule copyWith({
    int? id,
    int? subjectId,
    String? type,
    int? dayOfWeek,
    String? date,
    String? startTime,
    String? endTime,
    String? room,
  }) {
    return Schedule(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      type: type ?? this.type,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
    );
  }
}
