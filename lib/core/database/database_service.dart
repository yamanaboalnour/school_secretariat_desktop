import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/student.dart';
import '../../models/student_year_result.dart';

class DatabaseService {
  DatabaseService({this._databasePath});

  final String? _databasePath;
  Database? _database;

  Future<Database> get database async {
    _database ??= await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasePath = _databasePath;
    if (databasePath != null) {
      final dir = Directory(databasePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final dbFile = p.join(dir.path, 'school_secretariat.db');
      return openDatabase(
        dbFile,
        version: 1,
        onCreate: _onCreate,
      );
    }

    final directory = await getApplicationSupportDirectory();
    final dbPath = p.join(directory.path, 'school_secretariat.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<bool> hasImportedData() async {
    final db = await database;
    final totalStudents = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM students'),
    );
    return (totalStudents ?? 0) > 0;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        general_id INTEGER UNIQUE,
        national_id TEXT,
        first_name TEXT,
        last_name TEXT,
        nickname TEXT,
        full_name TEXT,
        father_name TEXT,
        mother_name TEXT,
        gender TEXT,
        birth_date TEXT,
        mobile TEXT,
        current_grade TEXT,
        current_section TEXT,
        school_entry_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE student_year_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        academic_year TEXT NOT NULL,
        grade INTEGER,
        section TEXT,
        status TEXT,
        result_value TEXT,
        raw_value TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        UNIQUE (student_id, academic_year)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_students_general_id ON students (general_id)',
    );
    await db.execute(
      'CREATE INDEX idx_student_year_results_student_id ON student_year_results (student_id)',
    );
    await db.execute(
      'CREATE INDEX idx_student_year_results_academic_year ON student_year_results (academic_year)',
    );
  }

  Future<List<Student>> getStudents({String? search, int limit = 400}) async {
    final db = await database;

    String? where;
    List<Object?> whereArgs = [];

    if (search != null && search.trim().isNotEmpty) {
      final query = '%${search.trim().toLowerCase()}%';
      where = '''
        LOWER(COALESCE(first_name, '')) LIKE ? OR
        LOWER(COALESCE(last_name, '')) LIKE ? OR
        LOWER(COALESCE(nickname, '')) LIKE ? OR
        LOWER(COALESCE(full_name, '')) LIKE ? OR
        CAST(general_id AS TEXT) LIKE ? OR
        LOWER(COALESCE(national_id, '')) LIKE ?
      ''';
      whereArgs = [query, query, query, query, query, query];
    }

    final rows = await db.query(
      'students',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'COALESCE(CAST(general_id AS INTEGER), 999999999) ASC, id ASC',
      limit: limit,
    );

    return rows.map((row) => Student.fromMap(row)).toList();
  }

  Future<Student?> getStudentById(int id) async {
    final db = await database;
    final rows = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Student.fromMap(rows.first);
  }

  Future<List<StudentYearResult>> getStudentYearResults(int studentId) async {
    final db = await database;
    final rows = await db.query(
      'student_year_results',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'academic_year ASC',
    );

    return rows.map((row) => StudentYearResult.fromMap(row)).toList();
  }

  Future<Map<String, int>> getDashboardStats() async {
    final db = await database;
    final totalStudents = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM students'),
    ) ?? 0;

    final studentsWithResults = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(DISTINCT student_id) FROM student_year_results',
      ),
    ) ?? 0;

    final studentsWithoutResults = Sqflite.firstIntValue(
      await db.rawQuery('''
        SELECT COUNT(*)
        FROM students s
        LEFT JOIN student_year_results r ON r.student_id = s.id
        WHERE r.student_id IS NULL
      '''),
    ) ?? 0;

    final yearlyRecords = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM student_year_results'),
    ) ?? 0;

    return {
      'totalStudents': totalStudents,
      'studentsWithResults': studentsWithResults,
      'studentsWithoutResults': studentsWithoutResults,
      'yearlyRecords': yearlyRecords,
    };
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
