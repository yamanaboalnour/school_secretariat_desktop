class StudentYearResult {
  const StudentYearResult({
    this.id,
    required this.studentId,
    required this.academicYear,
    this.grade,
    this.section,
    this.status,
    this.resultValue,
    required this.rawValue,
  });

  final int? id;
  final int studentId;
  final String academicYear;
  final int? grade;
  final String? section;
  final String? status;
  final String? resultValue;
  final String rawValue;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'academic_year': academicYear,
      'grade': grade,
      'section': section,
      'status': status,
      'result_value': resultValue,
      'raw_value': rawValue,
    };
  }

  factory StudentYearResult.fromMap(Map<String, Object?> map) {
    return StudentYearResult(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      academicYear: map['academic_year'] as String,
      grade: map['grade'] as int?,
      section: map['section'] as String?,
      status: map['status'] as String?,
      resultValue: map['result_value'] as String?,
      rawValue: map['raw_value'] as String,
    );
  }
}
