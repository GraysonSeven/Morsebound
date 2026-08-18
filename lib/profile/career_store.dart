import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../cloud/cloud_sync_hook.dart';
import 'career_profile.dart';

class CareerStore {
  static const _key = 'morsebound_career_v1';
  static const _updatedKey = 'morsebound_career_updated_ms';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<CareerProfile> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return CareerProfile();

    try {
      return CareerProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return CareerProfile();
    }
  }

  Future<void> save(CareerProfile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
    await _prefs.setInt(_updatedKey, DateTime.now().millisecondsSinceEpoch);
    CloudSyncHook.notifyLocalChanged();
  }

  Future<int> updatedAtMs() async => await _prefs.getInt(_updatedKey) ?? 0;

  Future<void> restoreFromCloud(CareerProfile profile, int modifiedMs) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
    await _prefs.setInt(_updatedKey, modifiedMs);
  }

  Future<void> reset() async {
    await _prefs.remove(_key);
    await _prefs.setInt(_updatedKey, DateTime.now().millisecondsSinceEpoch);
    CloudSyncHook.notifyLocalChanged();
  }
}



