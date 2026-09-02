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
    final logoBytes = (await rootBundle.load('assets/logo.png')).buffer.asUint8List();

    final pdf = pw.Document();
    final academicSequence = AcademicSequenceService.build(student, results);

    final rows = academicSequence.entries.isEmpty
        ? [
            pw.TableRow(
              children: [
                _tableCell(arabicFont, 'لا توجد بيانات'),
                _tableCell(arabicFont, 'غير محدد'),
                _tableCell(arabicFont, 'غير محدد'),
                _tableCell(arabicFont, 'غير محدد'),
              ],
            ),
          ]
        : academicSequence.entries
            .map(
              (entry) => pw.TableRow(
                children: [
                  _tableCell(arabicFont, entry.academicYear),
                  _tableCell(arabicFont, entry.section),
                  _tableCell(arabicFont, entry.status),
                  _tableCell(arabicFont, entry.rawValue),
                ],
              ),
            )
            .toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(18),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF9F7F1),
                      border: pw.Border.all(
                        color: PdfColor.fromInt(0xFF0E5D54),
                        width: 1.2,
                      ),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'الرقم العام: ${student.generalId ?? 'غير محدد'}',
                              style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'الرقم الوطني: ${student.nationalId ?? 'غير محدد'}',
                              style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            ),
                          ],
                        ),
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 52,
                              height: 52,
                              child: pw.Image(
                                pw.MemoryImage(logoBytes),
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              schoolName,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: arabicFont,
                                fontSize: 15,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF0D3A35),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    documentTitle,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0B3C35),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF7F3E8),
                      border: pw.Border.all(
                        color: PdfColor.fromInt(0xFFB38A34),
                        width: 1.1,
                      ),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          children: [
                            _studentField(arabicFont, 'اسم الطالب', _displayName(student)),
                            _studentField(arabicFont, 'اسم الأب', student.fatherName ?? 'غير محدد'),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          children: [
                            _studentField(arabicFont, 'اسم الأم', student.motherName ?? 'غير محدد'),
                            _studentField(arabicFont, 'تاريخ الميلاد', student.birthDate ?? 'غير محدد'),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          children: [
                            _studentField(arabicFont, 'الصف الحالي', student.currentGrade ?? 'غير محدد'),
                            _studentField(arabicFont, 'الشعبة', student.currentSection ?? 'غير محدد'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  pw.Text(
                    'التسلسل الدراسي',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0E5D54),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColor.fromInt(0xFF0A3B37)),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(80),
                      1: pw.FixedColumnWidth(110),
                      2: pw.FixedColumnWidth(130),
                      3: pw.FixedColumnWidth(190),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0EA)),
                        children: [
                          _tableHeaderCell(arabicFont, 'السنة'),
                          _tableHeaderCell(arabicFont, 'الصف'),
                          _tableHeaderCell(arabicFont, 'الحالة'),
                          _tableHeaderCell(arabicFont, 'القيمة الأصلية'),
                        ],
                      ),
                      ...rows,
                    ],
                  ),
                  pw.Spacer(),
                  pw.Container(
                    padding: const pw.EdgeInsets.only(top: 12),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'ملاحظات:',
                              style: pw.TextStyle(font: arabicFont, fontSize: 9),
                            ),
                            pw.Text(
                              'تعتمد الوثيقة على البيانات المسجلة محلياً داخل النظام.',
                              style: pw.TextStyle(font: arabicFont, fontSize: 8),
                            ),
                          ],
                        ),
                        pw.Text(
                          'تاريخ الطباعة: ${DateTime.now().toLocal().toString().substring(0, 10)}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 8),
                        ),
                      ],
                    ),
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
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6),
        child: pw.Text(
          '$label: $value',
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(font: font, fontSize: 9),
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(pw.Font font, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _tableCell(pw.Font font, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 9),
      ),
    );
  }

  static String _displayName(Student student) {
    final nameParts = [
      student.firstName,
      student.lastName,
      student.nickname,
      student.fullName,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (nameParts.isEmpty) {
      return 'غير محدد';
    }

    final combined = nameParts.join(' ');
    return combined.isEmpty ? 'غير محدد' : combined;
  }
}
