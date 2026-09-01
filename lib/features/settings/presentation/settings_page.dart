import 'package:flutter/material.dart';

import '../../../shared/widgets/page_placeholder.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PagePlaceholder(
      title: 'الإعدادات',
      subtitle: 'الإعدادات العامة للتطبيق وتخصيص مهام المدرسة.\nسيتم إضافة الخيارات لاحقًا.',
    );
  }
}
