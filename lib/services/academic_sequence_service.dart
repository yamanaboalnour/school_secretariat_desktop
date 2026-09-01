import '../models/student.dart';
import '../models/student_year_result.dart';

class AcademicSequenceEntry {
  const AcademicSequenceEntry({
    required this.academicYear,
    required this.grade,
    required this.section,
    required this.status,
    required this.rawValue,
  });

  final String academicYear;
  final String grade;
  final String section;
  final String status;
  final String rawValue;
}

class AcademicSequence {
  const AcademicSequence({
    required this.student,
    required this.entries,
  });

  final Student student;
  final List<AcademicSequenceEntry> entries;
}

class AcademicSequenceService {
  static AcademicSequence build(Student student, List<StudentYearResult> results) {
    final sortedResults = [...results]
      ..sort((a, b) => a.academicYear.compareTo(b.academicYear));

    final entries = sortedResults
        .map(
          (result) => AcademicSequenceEntry(
            academicYear: result.academicYear,
            grade: result.grade?.toString() ?? 'غير محدد',
            section: result.section ?? 'غير محدد',
            status: result.status ?? 'غير محدد',
            rawValue: result.rawValue,
          ),
        )
        .toList();

    return AcademicSequence(student: student, entries: entries);
  }
}
