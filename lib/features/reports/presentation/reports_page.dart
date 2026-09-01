import 'package:flutter/material.dart';

import '../../../shared/widgets/page_placeholder.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholder(
      title: 'التقارير',
      subtitle: 'عرض التقارير والملخصات المتعلقة بالطلاب والتسلسل الدراسي.\nسيتم إضافة التقارير الدقيقة لاحقًا.',
    );
  }
}
