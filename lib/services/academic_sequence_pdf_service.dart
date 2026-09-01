import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/student.dart';
import '../models/student_year_result.dart';
import 'academic_sequence_service.dart';
import 'app_settings_service.dart';

class AcademicSequencePdfService {
  static Future<Uint8List> generatePdf(
    Student student,
    List<StudentYearResult> results,
  ) async {
    final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final arabicFont = pw.Font.ttf(fontData);
    final schoolName = await AppSettingsService.getSchoolName();
    final documentTitle = await AppSettingsService.getSchoolHeader();

    final pdf = pw.Document();
    final academicSequence = AcademicSequenceService.build(student, results);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    schoolName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    documentTitle,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _studentField(arabicFont, 'اسم الطالب', _displayName(student)),
                        _studentField(arabicFont, 'الرقم العام', '${student.generalId ?? 'غير محدد'}'),
                        _studentField(arabicFont, 'الرقم الوطني', student.nationalId ?? 'غير محدد'),
                        _studentField(arabicFont, 'اسم الأب', student.fatherName ?? 'غير محدد'),
                        _studentField(arabicFont, 'اسم الأم', student.motherName ?? 'غير محدد'),
                        _studentField(arabicFont, 'تاريخ الميلاد', student.birthDate ?? 'غير محدد'),
                        _studentField(arabicFont, 'الصف الحالي', student.currentGrade ?? 'غير محدد'),
                        _studentField(arabicFont, 'الشعبة', student.currentSection ?? 'غير محدد'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'التسلسل الدراسي:',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey700),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(90),
                      1: pw.FixedColumnWidth(110),
                      2: pw.FixedColumnWidth(110),
                      3: pw.FixedColumnWidth(180),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _tableHeaderCell(arabicFont, 'السنة'),
                          _tableHeaderCell(arabicFont, 'الصف'),
                          _tableHeaderCell(arabicFont, 'الحالة'),
                          _tableHeaderCell(arabicFont, 'القيمة الأصلية'),
                        ],
                      ),
                      ...academicSequence.entries.map(
                        (entry) => pw.TableRow(
                          children: [
                            _tableCell(arabicFont, entry.academicYear),
                            _tableCell(arabicFont, entry.section),
                            _tableCell(arabicFont, entry.status),
                            _tableCell(arabicFont, entry.rawValue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printPdf(
    Student student,
    List<StudentYearResult> results,
  ) async {
    final pdfBytes = await generatePdf(student, results);
    await Printing.layoutPdf(
      name: 'تسلسل_دراسي_${student.generalId ?? student.id ?? 'student'}',
      onLayout: (_) async => pdfBytes,
    );
  }

  static pw.Widget _studentField(
    pw.Font font,
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        '$label: $value',
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(pw.Font font, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _tableCell(pw.Font font, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
    );
  }

  static String _displayName(Student student) {
    final nameParts = [
      student.firstName,
      student.lastName,
      student.nickname,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (nameParts.isEmpty) {
      return student.fullName ?? 'غير محدد';
    }

    final combined = nameParts.join(' ');
    return combined.isEmpty ? 'غير محدد' : combined;
  }
}
