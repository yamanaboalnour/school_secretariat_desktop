import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/student_import_service.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final StudentImportService _importService = StudentImportService();

  String? _studentsPath;
  String? _resultsPath;
  bool _loading = false;
  String? _errorMessage;
  StudentImportSummary? _summary;

  Future<void> _pickCsvFile({required bool isStudents}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result.isEmpty || result.single.path == null) {
      return;
    }

    setState(() {
      if (isStudents) {
        _studentsPath = result.single.path!;
      } else {
        _resultsPath = result.single.path!;
      }
    });
  }

  Future<void> _runImport() async {
    if (_studentsPath == null || _resultsPath == null) {
      setState(() {
        _errorMessage = 'يرجى اختيار ملف الطلاب وملف النتائج أولاً.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _summary = null;
    });

    try {
      final summary = await _importService.importFromFiles(
        studentsCsvPath: _studentsPath!,
        resultsCsvPath: _resultsPath!,
      );

      setState(() {
        _summary = summary;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'استيراد البيانات',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر ملفي السجل العام للطلاب وملف النتائج ثم قم بالاستيراد إلى SQLite المحلي.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _FilePickerCard(
                      title: 'ملف الطلاب',
                      value: _studentsPath ?? 'لم يتم اختيار الملف',
                      onTap: () => _pickCsvFile(isStudents: true),
                    ),
                    _FilePickerCard(
                      title: 'ملف النتائج',
                      value: _resultsPath ?? 'لم يتم اختيار الملف',
                      onTap: () => _pickCsvFile(isStudents: false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _runImport,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_loading ? 'جارٍ الاستيراد...' : 'بدء الاستيراد'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
                if (_summary != null) ...[
                  const SizedBox(height: 22),
                  _ImportSummaryCard(summary: _summary!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilePickerCard extends StatelessWidget {
  const _FilePickerCard({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportSummaryCard extends StatelessWidget {
  const _ImportSummaryCard({required this.summary});

  final StudentImportSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricTile(label: 'الطلاب المستوردون', value: '${summary.studentsImported}'),
      _MetricTile(label: 'سجلات النتائج المستوردة', value: '${summary.resultRowsImported}'),
      _MetricTile(label: 'الطلاب بدون نتائج', value: '${summary.studentsWithoutResults}'),
      _MetricTile(label: 'النتائج غير المرتبطة', value: '${summary.unmatchedResultRows}'),
      _MetricTile(label: 'التكرارات المحظورة', value: '${summary.duplicateStudentsBlocked + summary.duplicateYearResultsBlocked}'),
      _MetricTile(label: 'القيم غير المفهومة', value: '${summary.unknownAcademicValues}'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نتيجة الاستيراد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items,
          ),
          if (summary.unknownValueSamples.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'أمثلة للقيم غير المفهومة:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.unknownValueSamples
                  .map((value) => Chip(label: Text(value)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
