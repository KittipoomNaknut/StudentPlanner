class Note {
  final int? id;
  final int subjectId;
  final String title;
  final String content;
  final String updatedAt; // ISO8601

  const Note({
    this.id,
    required this.subjectId,
    required this.title,
    this.content = '',
    required this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'title': title,
      'content': content,
      'updated_at': updatedAt,
    };
  }

  Note copyWith({
    int? id,
    int? subjectId,
    String? title,
    String? content,
    String? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
