import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:school_secretariat_desktop/core/database/database_service.dart';
import 'package:school_secretariat_desktop/services/academic_result_parser.dart';
import 'package:school_secretariat_desktop/services/student_import_service.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  group('AcademicResultParser', () {
    test('parses successful grade result', () {
      final result = AcademicResultParser.parse('ناجح / 7');

      expect(result.status, 'ناجح');
      expect(result.grade, 7);
      expect(result.resultValue, 'ناجح / 7');
      expect(result.isRecognized, isTrue);
    });

    test('parses support-grade result', () {
      final result = AcademicResultParser.parse('ناجح بالمساعدة / 8');

      expect(result.status, 'ناجح بالمساعدة');
      expect(result.grade, 8);
      expect(result.isRecognized, isTrue);
    });

    test('treats empty result as unknown', () {
      final result = AcademicResultParser.parse('');

      expect(result.status, isNull);
      expect(result.grade, isNull);
      expect(result.isRecognized, isFalse);
    });

    test('keeps unexpected values as unknown without losing raw data', () {
      final result = AcademicResultParser.parse('مستمر');

      expect(result.status, isNull);
      expect(result.grade, isNull);
      expect(result.rawValue, 'مستمر');
      expect(result.isRecognized, isFalse);
    });
  });

  group('Real data import', () {
    test('imports the legacy school CSV files without duplicating records', () async {
      final tempDir = await Directory.systemTemp.createTemp('school_secretariat_import_');
      final dbService = DatabaseService(databasePath: tempDir.path);

      try {
        final importer = StudentImportService(databaseService: dbService);
        final summary = await importer.importFromFiles(
          studentsCsvPath: r'Y:\Programming projects\Flutter\school_secretariat_app\assets\students\students.csv',
          resultsCsvPath: r'Y:\Programming projects\Flutter\school_secretariat_app\assets\Record the results of the years for students.csv',
        );

        expect(summary.studentsImported, greaterThan(0));
        expect(summary.resultRowsImported, greaterThan(0));
        expect(summary.unknownAcademicValues, greaterThanOrEqualTo(0));
        expect(summary.importedStudentExamples, isNotEmpty);
        expect(summary.importedAcademicExamples, isNotEmpty);

        final db = await dbService.database;
        final studentCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM students'),
            ) ??
            0;
        final resultCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM student_year_results'),
            ) ??
            0;

        expect(studentCount, summary.studentsImported);
        expect(resultCount, summary.resultRowsImported);
      } finally {
        await dbService.close();
        await tempDir.delete(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 10))); 
  });
}
