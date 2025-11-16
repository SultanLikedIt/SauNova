import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static late String _themeString;
  static String get themeString => _themeString;

  static late DateTime? _activeSessionStartTime;
  static DateTime? get activeSessionStartTime => _activeSessionStartTime;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _themeString = _prefs.getString('themeString') ?? 'system';
    _activeSessionStartTime = _prefs.getString('activeSessionStartTime') != null
        ? DateTime.parse(_prefs.getString('activeSessionStartTime')!)
        : null;
  }

  static Future<void> setThemeString(String value) async {
    _themeString = value;
    await _prefs.setString('themeString', value);
  }

  static Future<void> setActiveSessionStartTime(DateTime? value) async {
    _activeSessionStartTime = value;
    if (value != null) {
      await _prefs.setString('activeSessionStartTime', value.toIso8601String());
    } else {
      await _prefs.remove('activeSessionStartTime');
    }
  }
}
