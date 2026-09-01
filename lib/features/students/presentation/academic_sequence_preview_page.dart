import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../models/student.dart';
import '../../../models/student_year_result.dart';
import '../../../services/academic_sequence_pdf_service.dart';

class AcademicSequencePreviewPage extends StatefulWidget {
  const AcademicSequencePreviewPage({
    super.key,
    required this.student,
    required this.results,
  });

  final Student student;
  final List<StudentYearResult> results;

  @override
  State<AcademicSequencePreviewPage> createState() =>
      _AcademicSequencePreviewPageState();
}

class _AcademicSequencePreviewPageState extends State<AcademicSequencePreviewPage> {
  late final Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = AcademicSequencePdfService.generatePdf(
      widget.student,
      widget.results,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة التسلسل الدراسي'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await AcademicSequencePdfService.printPdf(
                  widget.student,
                  widget.results,
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تعذر إنشاء الطباعة: $error')),
                );
              }
            },
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة',
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ أثناء إنشاء المعاينة: ${snapshot.error}'),
            );
          }

          final pdfBytes = snapshot.data;
          if (pdfBytes == null) {
            return const Center(child: Text('تعذر إنشاء وثيقة المعاينة.'));
          }

          return PdfPreview(
            build: (_) async => pdfBytes,
            allowPrinting: true,
            allowSharing: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}
