import 'package:flutter/material.dart';

import '../../../services/app_settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _documentTitleController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final schoolName = await AppSettingsService.getSchoolName();
    final documentTitle = await AppSettingsService.getSchoolHeader();

    if (!mounted) return;

    setState(() {
      _schoolNameController.text = schoolName;
      _documentTitleController.text = documentTitle;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    await AppSettingsService.saveSchoolName(_schoolNameController.text);
    await AppSettingsService.saveSchoolHeader(_documentTitleController.text);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ إعدادات المدرسة بنجاح.')),
    );
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _documentTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
                  Text(
                    'الإعدادات الأساسية',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _schoolNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المدرسة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _documentTitleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان وثيقة التسلسل الدراسي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ الإعدادات'),
                  ),
                ],
              ),
            ),
    );
  }
}
