import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'morse_code.dart';
import 'morse_transfer.dart';

class MorseAudio {
  MorseAudio({Random? random}) : _random = random ?? Random();

  final AudioPlayer _player = AudioPlayer();
  final Random _random;

  Future<bool> playCharacter(
    String character, {
    MorseSignalVariant variant = MorseSignalVariant.clean,
  }) async {
    try {
      await _player.play(
        AssetSource(_assetName(character, variant)),
      );

      await Future<void>.delayed(
        Duration(
          milliseconds: _assetDurationMs(
            character,
            variant: variant,
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> playText(
    String text, {
    int interCharacterGapMs = 420,
    int wordGapMs = 850,
    int transferLevel = 0,
  }) async {
    final normalized = text.toUpperCase();

    for (var i = 0; i < normalized.length; i++) {
      final character = normalized[i];

      if (character == ' ') {
        await Future<void>.delayed(
          Duration(milliseconds: wordGapMs),
        );
        continue;
      }

      if (!MorseCode.patterns.containsKey(character)) return false;

      final variant = MorseTransferProfile.variantFor(
        level: transferLevel,
        roll: _random.nextDouble(),
      );

      final ok = await playCharacter(
        character,
        variant: variant,
      );
      if (!ok) return false;

      if (i < normalized.length - 1) {
        await Future<void>.delayed(
          Duration(milliseconds: interCharacterGapMs),
        );
      }
    }

    return true;
  }

  String _assetName(
    String character,
    MorseSignalVariant variant,
  ) {
    final c = character.toLowerCase();

    switch (variant) {
      case MorseSignalVariant.lowPitch:
        return 'audio/morse/${c}_field_low.wav';
      case MorseSignalVariant.highPitch:
        return 'audio/morse/${c}_field_high.wav';
      case MorseSignalVariant.radio:
        return 'audio/morse/${c}_radio.wav';
      case MorseSignalVariant.clean:
        return MorseCode.assetNameFor(character);
    }
  }

  int _assetDurationMs(
    String character, {
    required MorseSignalVariant variant,
  }) {
    final unitMs = switch (variant) {
      MorseSignalVariant.lowPitch => 64,
      MorseSignalVariant.highPitch => 56,
      MorseSignalVariant.radio => 60,
      MorseSignalVariant.clean => 60,
    };

    final pattern = MorseCode.patternFor(character);
    var duration = 215;

    for (var i = 0; i < pattern.length; i++) {
      duration += pattern[i] == '.' ? unitMs : unitMs * 3;
      if (i < pattern.length - 1) {
        duration += unitMs;
      }
    }

    return duration;
  }

  Future<void> dispose() => _player.dispose();
}
