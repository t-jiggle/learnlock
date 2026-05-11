import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnlock/models/app_settings.dart';

class StorageService {
  static const _settingsKey = 'app_settings';
  static const _activeChildKey = 'active_child_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  AppSettings loadSettings() {
    final json = _prefs.getString(_settingsKey);
    if (json == null) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  String? get activeChildId => _prefs.getString(_activeChildKey);

  Future<void> setActiveChildId(String id) =>
      _prefs.setString(_activeChildKey, id);

  Future<void> clearActiveChild() => _prefs.remove(_activeChildKey);
}
