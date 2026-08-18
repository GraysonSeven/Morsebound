import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../cloud/cloud_sync_hook.dart';
import 'app_settings.dart';

class SettingsStore {
  static const _key = 'morsebound_settings_v1';
  static const _updatedKey = 'morsebound_settings_updated_ms';

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
    await _prefs.setInt(_updatedKey, DateTime.now().millisecondsSinceEpoch);
    CloudSyncHook.notifyLocalChanged();
  }

  Future<int> updatedAtMs() async => await _prefs.getInt(_updatedKey) ?? 0;

  Future<void> restoreFromCloud(AppSettings settings, int modifiedMs) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
    await _prefs.setInt(_updatedKey, modifiedMs);
  }

  Future<void> reset() async {
    await _prefs.remove(_key);
    await _prefs.setInt(_updatedKey, DateTime.now().millisecondsSinceEpoch);
    CloudSyncHook.notifyLocalChanged();
  }
}



