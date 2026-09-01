import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../core/database/database_service.dart';
import '../models/student.dart';
import '../models/student_year_result.dart';
import 'academic_result_parser.dart';

class StudentImportSummary {
  const StudentImportSummary({
    required this.studentsImported,
    required this.resultRowsImported,
    required this.studentsWithoutResults,
    required this.unmatchedResultRows,
    required this.duplicateStudentsBlocked,
    required this.duplicateYearResultsBlocked,
    required this.unknownAcademicValues,
    required this.unknownValueSamples,
    required this.importedStudentExamples,
    required this.importedAcademicExamples,
  });

  final int studentsImported;
  final int resultRowsImported;
  final int studentsWithoutResults;
  final int unmatchedResultRows;
  final int duplicateStudentsBlocked;
  final int duplicateYearResultsBlocked;
  final int unknownAcademicValues;
  final List<String> unknownValueSamples;
  final List<Student> importedStudentExamples;
  final List<StudentYearResult> importedAcademicExamples;
}

class StudentImportService {
  StudentImportService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  final DatabaseService _databaseService;

  Future<StudentImportSummary> importFromFiles({
    required String studentsCsvPath,
    required String resultsCsvPath,
  }) async {
    final db = await _databaseService.database;

    final studentsData = await _readCsvFile(studentsCsvPath);
    final resultsData = await _readCsvFile(resultsCsvPath);

    if (studentsData.isEmpty || resultsData.isEmpty) {
      throw StateError('One or more CSV files are empty or missing.');
    }

    final studentHeader = studentsData.first;
    final resultsHeader = resultsData.first;

    if (_findColumnIndex(studentHeader, 'GeneralID') == -1) {
      throw StateError('GeneralID column not found in students.csv');
    }

    if (_findColumnIndex(resultsHeader, 'NoStudents') == -1) {
      throw StateError('NoStudents column not found in results CSV');
    }

    final students = studentsData.skip(1).where((row) => row.isNotEmpty).toList();
    final results = resultsData.skip(1).where((row) => row.isNotEmpty).toList();

    final studentRows = <Student>[];
    final seenStudentGenerals = <int>{};
    int duplicateStudentsBlocked = 0;

    for (final row in students) {
      final map = _normalizeRow(studentHeader, row);
      final generalId = _parseInt(map['GeneralID']);
      if (generalId == null) {
        continue;
      }

      if (!seenStudentGenerals.add(generalId)) {
        duplicateStudentsBlocked++;
        continue;
      }

      final newStudent = Student(
        generalId: generalId,
        nationalId: _cleanString(map['الرقم الوطني']),
        firstName: _cleanString(map['اسم الطالب']),
        lastName: _cleanString(map['كنية الطالب']),
        nickname: _cleanString(map['كنية الطالب']),
        fullName: _cleanString(map['الاسم الكامل']),
        fatherName: _cleanString(map['اسم الاب']),
        motherName: _cleanString(map['اسم الأم']),
        gender: _cleanString(map['الجنس']),
        birthDate: _cleanString(map['تاريخ الولادة']),
        mobile: _cleanString(map['موبايل الطالب']),
        currentGrade: _cleanString(map['الصف']),
        currentSection: _cleanString(map['الشعبة']),
        schoolEntryDate: _cleanString(map['تاريخ دخوله للثانوية']),
      );

      studentRows.add(newStudent);
    }

    for (final student in studentRows) {
      await db.insert(
        'students',
        student.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final mappedStudentIds = <int, int>{};
    final allStudentRows = await db.query('students');
    for (final item in allStudentRows) {
      final generalId = item['general_id'] as int?;
      final studentId = item['id'] as int?;
      if (generalId != null && studentId != null) {
        mappedStudentIds[generalId] = studentId;
      }
    }

    final yearColumns = resultsHeader
        .asMap()
        .entries
        .where((entry) => RegExp(r'^\d{4}-\d{4}$').hasMatch(entry.value.trim()))
        .map((entry) => entry.key)
        .toList();

    int resultRowsImported = 0;
    int duplicateYearResultsBlocked = 0;
    int unmatchedResultRows = 0;
    final unknownValueSamples = <String>[];
    int unknownAcademicValues = 0;
    final importedAcademicExamples = <StudentYearResult>[];
    final seenYearResults = <String>{};

    for (final row in results) {
      final map = _normalizeRow(resultsHeader, row);
      final generalId = _parseInt(map['NoStudents']);
      if (generalId == null) {
        continue;
      }

      final studentId = mappedStudentIds[generalId];
      if (studentId == null) {
        unmatchedResultRows++;
        continue;
      }

      for (final yearIndex in yearColumns) {
        final academicYear = (resultsHeader[yearIndex]).trim();
        final rawValue = _cleanString(map[academicYear]);
        if (rawValue == null || rawValue.isEmpty) {
          continue;
        }

        final parsed = AcademicResultParser.parse(rawValue);
        final status = parsed.status;
        final grade = parsed.grade;
        final resultValue = parsed.resultValue;

        if (!parsed.isRecognized) {
          unknownAcademicValues++;
          if (unknownValueSamples.length < 5) {
            unknownValueSamples.add(rawValue);
          }
        }

        final resultKey = '$studentId|$academicYear';
        if (!seenYearResults.add(resultKey)) {
          duplicateYearResultsBlocked++;
          continue;
        }

        final academicRecord = StudentYearResult(
          studentId: studentId,
          academicYear: academicYear,
          grade: grade,
          section: _cleanString(map['الشعبة']) ?? '',
          status: status,
          resultValue: resultValue,
          rawValue: rawValue,
        );

        final insertedId = await db.insert(
          'student_year_results',
          academicRecord.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        if (insertedId == 0) {
          duplicateYearResultsBlocked++;
          continue;
        }

        resultRowsImported++;
        if (importedAcademicExamples.length < 5) {
          importedAcademicExamples.add(academicRecord);
        }
      }
    }

    final totalStudents = await db.query('students');
    final studentIdsWithYearResults = await db.rawQuery(
      'SELECT DISTINCT student_id FROM student_year_results',
    );
    final studentsWithoutResults = totalStudents.length - studentIdsWithYearResults.length;

    final importedStudentExamples = <Student>[];
    final studentList = await db.query(
      'students',
      limit: 5,
      orderBy: 'id ASC',
    );
    for (final item in studentList) {
      importedStudentExamples.add(
        Student.fromMap(item),
      );
    }

    return StudentImportSummary(
      studentsImported: totalStudents.length,
      resultRowsImported: resultRowsImported,
      studentsWithoutResults: studentsWithoutResults,
      unmatchedResultRows: unmatchedResultRows,
      duplicateStudentsBlocked: duplicateStudentsBlocked,
      duplicateYearResultsBlocked: duplicateYearResultsBlocked,
      unknownAcademicValues: unknownAcademicValues,
      unknownValueSamples: unknownValueSamples,
      importedStudentExamples: importedStudentExamples,
      importedAcademicExamples: importedAcademicExamples,
    );
  }

  Future<List<List<String>>> _readCsvFile(String path) async {
    final file = File(path);
    final lines = await file.readAsLines(encoding: utf8);
    final rows = <List<String>>[];
    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      rows.add(_splitCsvLine(line));
    }
    return rows;
  }

  Map<String, String> _normalizeRow(List<String> header, List<String> rawRow) {
    final map = <String, String>{};
    for (var index = 0; index < header.length; index++) {
      final key = header[index].trim();
      final value = index < rawRow.length ? rawRow[index] : '';
      map[key] = _cleanString(value) ?? '';
    }
    return map;
  }

  List<String> _splitCsvLine(String line) {
    final fields = <String>[];
    final current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ';' && !inQuotes) {
        fields.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }

    fields.add(current.toString());
    return fields;
  }

  String? _cleanString(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value
        .replaceFirst('\ufeff', '')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }
    final booleanLike = normalized.toLowerCase();
    if (booleanLike.contains('فارغ') ||
        booleanLike == 'null' ||
        booleanLike == 'none' ||
        booleanLike == 'na' ||
        booleanLike == 'n/a') {
      return null;
    }
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  int? _parseInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'[^0-9-]'), '');
    if (cleaned.isEmpty) {
      return null;
    }
    return int.tryParse(cleaned);
  }

  int _findColumnIndex(List<String> headers, String target) {
    for (var i = 0; i < headers.length; i++) {
      if (headers[i].trim() == target) {
        return i;
      }
    }
    return -1;
  }
}
