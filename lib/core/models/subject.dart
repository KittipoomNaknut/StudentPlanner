class Subject {
  final int? id;
  final String name;
  final String code;
  final String color; // hex เช่น '#1565C0'
  final String teacher;
  final int credits;

  const Subject({
    this.id,
    required this.name,
    required this.code,
    required this.color,
    this.teacher = '',
    this.credits = 3,
  });

  // Map → Object (ตอนอ่านจาก SQLite)
  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String? ?? '',
      color: map['color'] as String,
      teacher: map['teacher'] as String? ?? '',
      credits: map['credits'] as int? ?? 3,
    );
  }

  // Object → Map (ตอนเขียนลง SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'code': code,
      'color': color,
      'teacher': teacher,
      'credits': credits,
    };
  }

  // สร้าง object ใหม่จากของเดิม แก้บางส่วน
  Subject copyWith({
    int? id,
    String? name,
    String? code,
    String? color,
    String? teacher,
    int? credits,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      color: color ?? this.color,
      teacher: teacher ?? this.teacher,
      credits: credits ?? this.credits,
    );
  }
}
