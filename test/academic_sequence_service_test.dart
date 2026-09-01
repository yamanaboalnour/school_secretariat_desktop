import 'package:flutter_test/flutter_test.dart';
import 'package:school_secretariat_desktop/models/student.dart';
import 'package:school_secretariat_desktop/models/student_year_result.dart';
import 'package:school_secretariat_desktop/services/academic_sequence_service.dart';

void main() {
  group('AcademicSequenceService', () {
    test('sorts academic years in chronological order and preserves raw values', () {
      final student = Student(
        id: 1,
        generalId: 100,
        fullName: 'أحمد محمد',
      );

      final results = [
        StudentYearResult(
          studentId: 1,
          academicYear: '2023-2024',
          section: 'ب',
          status: 'ناجح',
          grade: 8,
          rawValue: 'ناجح / 8',
        ),
        StudentYearResult(
          studentId: 1,
          academicYear: '2022-2023',
          section: 'أ',
          status: 'راسب',
          grade: 9,
          rawValue: 'راسب / 9',
        ),
      ];

      final sequence = AcademicSequenceService.build(student, results);

      expect(sequence.entries.length, 2);
      expect(sequence.entries.first.academicYear, '2022-2023');
      expect(sequence.entries.last.academicYear, '2023-2024');
      expect(sequence.entries.first.rawValue, 'راسب / 9');
    });

    test('keeps unknown and blank values without inventing data', () {
      final student = Student(id: 2, generalId: 200, fullName: 'سارة علي');

      final results = [
        StudentYearResult(
          studentId: 2,
          academicYear: '2024-2025',
          section: null,
          status: null,
          grade: null,
          rawValue: '',
        ),
        StudentYearResult(
          studentId: 2,
          academicYear: '2025-2026',
          section: 'ج',
          status: 'غير متقدم',
          grade: 9,
          rawValue: 'غير متقدم / 9',
        ),
      ];

      final sequence = AcademicSequenceService.build(student, results);

      expect(sequence.entries[0].section, 'غير محدد');
      expect(sequence.entries[0].status, 'غير محدد');
      expect(sequence.entries[0].grade, 'غير محدد');
      expect(sequence.entries[1].rawValue, 'غير متقدم / 9');
    });
  });
}
