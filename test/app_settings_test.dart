import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/settings/app_settings.dart';

void main() {
  test('audio pacing presets preserve fast character learning', () {
    final settings = AppSettings();

    settings.applyPacingPreset('Comfort');
    expect(settings.wordCharacterGapMs, 560);

    settings.applyPacingPreset('Fast');
    expect(settings.wordCharacterGapMs, 300);

    settings.applyPacingPreset('Standard');
    expect(settings.wordCharacterGapMs, 420);
  });
}
