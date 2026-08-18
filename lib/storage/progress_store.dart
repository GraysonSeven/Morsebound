import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../cloud/cloud_sync_hook.dart';
import '../learning/learning_model.dart';

class ProgressStore {
  static const _key = 'morsebound_learning_v1';
  static const _legacyKey = 'signal_runner_learning_v1';
  static const _updatedKey = 'morsebound_learning_updated_ms';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<LearningSnapshot> load() async {
    var raw = await _prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      raw = await _prefs.getString(_legacyKey);
      if (raw != null && raw.isNotEmpty) {
        await _prefs.setString(_key, raw);
      }
    }

    if (raw == null || raw.isEmpty) return LearningSnapshot.fresh();

    try {
      return LearningSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return LearningSnapshot.fresh();
    }
  }

  Future<void> save(LearningSnapshot snapshot) async {
    await _prefs.setString(_key, jsonEncode(snapshot.toJson()));
    await _prefs.setInt(_updatedKey, DateTime.now().millisecondsSinceEpoch);
    CloudSyncHook.notifyLocalChanged();
  }

  Future<int> updatedAtMs() async => await _prefs.getInt(_updatedKey) ?? 0;

  Future<void> restoreFromCloud(LearningSnapshot snapshot, int modifiedMs) async {
    await _prefs.setString(_key, jsonEncode(snapshot.toJson()));
    await _prefs.setInt(_updatedKey, modifiedMs);
  }

  Future<void> reset() async {
    await _prefs.remove(_key);
    await _prefs.remove(_legacyKey);
    await _prefs.setInt(_updatedKey, DateTime.now().millisecondsSinceEpoch);
    CloudSyncHook.notifyLocalChanged();
  }
}



