import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();

  static const String schoolNameKey = 'school_name';
  static const String schoolHeaderKey = 'school_header';
  static const String importCompletedKey = 'import_completed';

  static Future<String> getSchoolName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(schoolNameKey) ?? 'أمانة المدرسة';
  }

  static Future<void> saveSchoolName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(schoolNameKey, value.trim().isEmpty ? 'أمانة المدرسة' : value.trim());
  }

  static Future<String> getSchoolHeader() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(schoolHeaderKey) ?? 'وثيقة التسلسل الدراسي';
  }

  static Future<void> saveSchoolHeader(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(schoolHeaderKey, value.trim().isEmpty ? 'وثيقة التسلسل الدراسي' : value.trim());
  }

  static Future<bool> getImportCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(importCompletedKey) ?? false;
  }

  static Future<void> setImportCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(importCompletedKey, value);
  }
}
