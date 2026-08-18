import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsStore {
  static const _key = 'morsebound_settings_v1';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<AppSettings> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return AppSettings();

    try {
      return AppSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  Future<void> reset() async {
    await _prefs.remove(_key);
  }
}
