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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await AppSettingsService.saveSchoolName(_schoolNameController.text.trim());
    await AppSettingsService.saveSchoolHeader(_documentTitleController.text.trim());

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
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E5D54).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            size: 28,
                            color: Color(0xFF0E5D54),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'إعدادات المدرسة',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بيانات المؤسسة',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _schoolNameController,
                            textDirection: TextDirection.rtl,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'يرجى إدخال اسم المدرسة';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'اسم المدرسة',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.account_balance_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _documentTitleController,
                            textDirection: TextDirection.rtl,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'يرجى إدخال عنوان وثيقة التسلسل الدراسي';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'عنوان وثيقة التسلسل الدراسي',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: ElevatedButton.icon(
                                  onPressed: _saveSettings,
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text('حفظ الإعدادات'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
