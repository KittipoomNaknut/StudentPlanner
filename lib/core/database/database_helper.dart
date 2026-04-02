import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/assignment.dart';
import '../models/grade.dart';
import '../models/schedule.dart';
import '../models/note.dart';

class DatabaseHelper {
  // ── SINGLETON ─────────────────────────────────────────
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  // ── INIT ──────────────────────────────────────────────
  Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'student_planner.db');
    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        name    TEXT NOT NULL,
        code    TEXT DEFAULT '',
        color   TEXT NOT NULL DEFAULT '#1565C0',
        teacher TEXT DEFAULT '',
        credits INTEGER DEFAULT 3
      )
    ''');

    await db.execute('''
      CREATE TABLE assignments (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id  INTEGER NOT NULL,
        title       TEXT NOT NULL,
        description TEXT DEFAULT '',
        deadline    TEXT NOT NULL,
        status      TEXT DEFAULT 'pending',
        priority    TEXT DEFAULT 'medium',
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE grades (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        name       TEXT NOT NULL,
        score      REAL NOT NULL,
        max_score  REAL NOT NULL,
        weight     REAL DEFAULT 1.0,
        type       TEXT DEFAULT 'quiz',
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id  INTEGER NOT NULL,
        type        TEXT NOT NULL,
        day_of_week INTEGER,
        date        TEXT,
        start_time  TEXT NOT NULL,
        end_time    TEXT NOT NULL,
        room        TEXT DEFAULT '',
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        title      TEXT NOT NULL,
        content    TEXT DEFAULT '',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── SUBJECTS ──────────────────────────────────────────
  Future<int> insertSubject(Subject s) async {
    final db = await database;
    return await db.insert('subjects', s.toMap());
  }

  Future<List<Subject>> getSubjects() async {
    final db = await database;
    final maps = await db.query('subjects', orderBy: 'name ASC');
    return maps.map(Subject.fromMap).toList();
  }

  Future<Subject?> getSubject(int id) async {
    final db = await database;
    final maps = await db.query('subjects', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Subject.fromMap(maps.first);
  }

  Future<int> updateSubject(Subject s) async {
    final db = await database;
    return await db.update(
      'subjects',
      s.toMap(),
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    return await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
    // ON DELETE CASCADE จะลบ assignments, grades, schedules, notes ของวิชานี้ด้วย
  }

  // ── ASSIGNMENTS ───────────────────────────────────────
  Future<int> insertAssignment(Assignment a) async {
    final db = await database;
    return await db.insert('assignments', a.toMap());
  }

  Future<List<Assignment>> getAssignments({
    int? subjectId,
    String? status,
  }) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (subjectId != null) {
      where.add('subject_id = ?');
      whereArgs.add(subjectId);
    }
    if (status != null) {
      where.add('status = ?');
      whereArgs.add(status);
    }

    final maps = await db.query(
      'assignments',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'deadline ASC',
    );
    return maps.map(Assignment.fromMap).toList();
  }

  Future<int> updateAssignment(Assignment a) async {
    final db = await database;
    return await db.update(
      'assignments',
      a.toMap(),
      where: 'id = ?',
      whereArgs: [a.id],
    );
  }

  Future<int> deleteAssignment(int id) async {
    final db = await database;
    return await db.delete('assignments', where: 'id = ?', whereArgs: [id]);
  }

  // ── GRADES ────────────────────────────────────────────
  Future<int> insertGrade(Grade g) async {
    final db = await database;
    return await db.insert('grades', g.toMap());
  }

  Future<List<Grade>> getGrades(int subjectId) async {
    final db = await database;
    final maps = await db.query(
      'grades',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'type ASC',
    );
    return maps.map(Grade.fromMap).toList();
  }

  Future<int> updateGrade(Grade g) async {
    final db = await database;
    return await db.update(
      'grades',
      g.toMap(),
      where: 'id = ?',
      whereArgs: [g.id],
    );
  }

  Future<int> deleteGrade(int id) async {
    final db = await database;
    return await db.delete('grades', where: 'id = ?', whereArgs: [id]);
  }

  // ── SCHEDULES ─────────────────────────────────────────
  Future<int> insertSchedule(Schedule s) async {
    final db = await database;
    return await db.insert('schedules', s.toMap());
  }

  Future<List<Schedule>> getSchedules({int? subjectId, String? type}) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (subjectId != null) {
      where.add('subject_id = ?');
      whereArgs.add(subjectId);
    }
    if (type != null) {
      where.add('type = ?');
      whereArgs.add(type);
    }

    final maps = await db.query(
      'schedules',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'day_of_week ASC, start_time ASC',
    );
    return maps.map(Schedule.fromMap).toList();
  }

  Future<int> updateSchedule(Schedule s) async {
    final db = await database;
    return await db.update(
      'schedules',
      s.toMap(),
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final db = await database;
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // ── NOTES ─────────────────────────────────────────────
  Future<int> insertNote(Note n) async {
    final db = await database;
    return await db.insert('notes', n.toMap());
  }

  Future<List<Note>> getNotes({int? subjectId}) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: subjectId != null ? 'subject_id = ?' : null,
      whereArgs: subjectId != null ? [subjectId] : null,
      orderBy: 'updated_at DESC',
    );
    return maps.map(Note.fromMap).toList();
  }

  Future<int> updateNote(Note n) async {
    final db = await database;
    return await db.update(
      'notes',
      n.toMap(),
      where: 'id = ?',
      whereArgs: [n.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ── UTILITY ───────────────────────────────────────────
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
