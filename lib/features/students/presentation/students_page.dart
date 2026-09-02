import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/database/database_service.dart';
import '../../../models/student.dart';
import 'student_detail_page.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _databaseService.getStudents(limit: 500);
  }

  void _refreshStudents() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _studentsFuture = _databaseService.getStudents(
          search: _searchController.text,
          limit: 500,
        );
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم، الكنية، الرقم العام أو الرقم الوطني',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      prefixIcon: const Icon(Icons.search_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => _refreshStudents(),
                  ),
                ),
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton.icon(
                    onPressed: _refreshStudents,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('تحديث'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Student>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('حدث خطأ أثناء تحميل الطلاب: ${snapshot.error}'),
                  );
                }

                final students = snapshot.data ?? const <Student>[];

                if (students.isEmpty) {
                  return const Center(
                    child: Text('لا توجد بيانات للطلاب وفقًا للبحث الحالي.'),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 120,
                      ),
                      child: DataTable(
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        dataTextStyle: const TextStyle(color: Color(0xFF334155)),
                        columns: const [
                          DataColumn(label: Text('الاسم الكامل')),
                          DataColumn(label: Text('الرقم العام')),
                          DataColumn(label: Text('الرقم الوطني')),
                          DataColumn(label: Text('الصف')),
                          DataColumn(label: Text('الشعبة')),
                        ],
                        rows: students
                            .map(
                              (student) => DataRow(
                                mouseCursor: WidgetStateMouseCursor.clickable,
                                onSelectChanged: (_) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => StudentDetailPage(student: student),
                                    ),
                                  );
                                },
                                cells: [
                                  DataCell(Text(student.fullName ?? student.firstName ?? 'غير محدد')),
                                  DataCell(Text('${student.generalId ?? 'غير محدد'}')),
                                  DataCell(Text(student.nationalId ?? 'غير محدد')),
                                  DataCell(Text(student.currentGrade ?? 'غير محدد')),
                                  DataCell(Text(student.currentSection ?? 'غير محدد')),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
