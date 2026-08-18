import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'career_profile.dart';

class CareerStore {
  static const _key = 'morsebound_career_v1';

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
  }

  Future<void> reset() async {
    await _prefs.remove(_key);
  }
}
