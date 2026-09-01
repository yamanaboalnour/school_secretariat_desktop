class AcademicResultParseResult {
  const AcademicResultParseResult({
    required this.status,
    required this.grade,
    required this.resultValue,
    required this.rawValue,
    required this.isRecognized,
  });

  final String? status;
  final int? grade;
  final String? resultValue;
  final String rawValue;
  final bool isRecognized;
}

class AcademicResultParser {
  static AcademicResultParseResult parse(String? rawValue) {
    final raw = rawValue?.trim() ?? '';
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ');

    if (normalized.isEmpty) {
      return const AcademicResultParseResult(
        status: null,
        grade: null,
        resultValue: null,
        rawValue: '',
        isRecognized: false,
      );
    }

    final matchTextValue = RegExp(r'^(.*?)/\s*(\d+)$').firstMatch(normalized);
    if (matchTextValue != null) {
      final status = matchTextValue.group(1)?.trim();
      final gradeText = matchTextValue.group(2);
      final grade = int.tryParse(gradeText ?? '');
      if (status != null && status.isNotEmpty && grade != null) {
        return AcademicResultParseResult(
          status: status,
          grade: grade,
          resultValue: '$status / $grade',
          rawValue: normalized,
          isRecognized: true,
        );
      }
    }

    final fallbackMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(normalized);
    if (fallbackMatch != null) {
      final status = fallbackMatch.group(1)?.trim();
      final gradeText = fallbackMatch.group(2);
      final grade = int.tryParse(gradeText ?? '');
      if (status != null && status.isNotEmpty && grade != null) {
        return AcademicResultParseResult(
          status: status,
          grade: grade,
          resultValue: '$status / $grade',
          rawValue: normalized,
          isRecognized: true,
        );
      }
    }

    return AcademicResultParseResult(
      status: null,
      grade: null,
      resultValue: null,
      rawValue: normalized,
      isRecognized: false,
    );
  }
}
