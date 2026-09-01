import 'package:flutter/material.dart';

import '../../../core/database/database_service.dart';
import '../../../models/student.dart';
import '../../../models/student_year_result.dart';
import '../../../services/academic_sequence_pdf_service.dart';
import 'academic_sequence_preview_page.dart';

class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({super.key, required this.student});

  final Student student;

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final DatabaseService _databaseService = DatabaseService();

  late Future<List<StudentYearResult>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _databaseService.getStudentYearResults(widget.student.id ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطالب'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final results = await _resultsFuture;
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AcademicSequencePreviewPage(
                    student: widget.student,
                    results: results,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.preview_outlined),
            label: const Text('معاينة التسلسل الدراسي'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () async {
              try {
                final results = await _resultsFuture;
                await AcademicSequencePdfService.printPdf(
                  widget.student,
                  results,
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تعذر إنشاء PDF للطباعة: $error')),
                );
              }
            },
            icon: const Icon(Icons.print_outlined),
            label: const Text('طباعة'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StudentSummaryCard(student: widget.student),
            const SizedBox(height: 24),
            Text(
              'التسلسل الدراسي',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<StudentYearResult>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('حدثت مشكلة في تحميل التسلسل الدراسي: ${snapshot.error}'),
                    );
                  }

                  final results = snapshot.data ?? const <StudentYearResult>[];

                  if (results.isEmpty) {
                    return const Center(
                      child: Text('لا توجد بيانات سنوية لهذا الطالب في قاعدة البيانات.'),
                    );
                  }

                  return SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('العام الدراسي')),
                          DataColumn(label: Text('الصف')),
                          DataColumn(label: Text('الحالة')),
                          DataColumn(label: Text('القيمة الأصلية')),
                        ],
                        rows: results
                            .map(
                              (result) => DataRow(
                                cells: [
                                  DataCell(Text(result.academicYear)),
                                  DataCell(Text(result.section ?? 'غير محدد')),
                                  DataCell(Text(result.status ?? 'غير محدد')),
                                  DataCell(Text(result.rawValue)),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _StudentSummaryCard extends StatelessWidget {
  const _StudentSummaryCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _InfoChip(label: 'الاسم الكامل', value: student.fullName ?? student.firstName ?? 'غير محدد'),
          _InfoChip(label: 'الرقم العام', value: '${student.generalId ?? 'غير محدد'}'),
          _InfoChip(label: 'الرقم الوطني', value: student.nationalId ?? 'غير محدد'),
          _InfoChip(label: 'الصف الحالي', value: student.currentGrade ?? 'غير محدد'),
          _InfoChip(label: 'الشعبة', value: student.currentSection ?? 'غير محدد'),
          _InfoChip(label: 'اسم الأب', value: student.fatherName ?? 'غير محدد'),
          _InfoChip(label: 'اسم الأم', value: student.motherName ?? 'غير محدد'),
          _InfoChip(label: 'الجنس', value: student.gender ?? 'غير محدد'),
          _InfoChip(label: 'تاريخ الميلاد', value: student.birthDate ?? 'غير محدد'),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
