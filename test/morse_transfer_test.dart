import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/morse/morse_transfer.dart';

void main() {
  test('beginners remain on clean audio', () {
    expect(
      MorseTransferProfile.levelFor(
        unlockedCount: 8,
        overallMastery: 0.90,
        enabled: true,
      ),
      0,
    );

    expect(
      MorseTransferProfile.variantFor(level: 0, roll: 0.01),
      MorseSignalVariant.clean,
    );
  });

  test('transfer difficulty rises only with both breadth and mastery', () {
    expect(
      MorseTransferProfile.levelFor(
        unlockedCount: 12,
        overallMastery: 0.45,
        enabled: true,
      ),
      1,
    );

    expect(
      MorseTransferProfile.levelFor(
        unlockedCount: 20,
        overallMastery: 0.60,
        enabled: true,
      ),
      2,
    );

    expect(
      MorseTransferProfile.levelFor(
        unlockedCount: 30,
        overallMastery: 0.72,
        enabled: true,
      ),
      3,
    );
  });

  test('disabled transfer always remains clean', () {
    expect(
      MorseTransferProfile.levelFor(
        unlockedCount: 36,
        overallMastery: 1.0,
        enabled: false,
      ),
      0,
    );
  });

  test('advanced transfer includes radio texture but retains clean trials', () {
    expect(
      MorseTransferProfile.variantFor(level: 3, roll: 0.60),
      MorseSignalVariant.radio,
    );
    expect(
      MorseTransferProfile.variantFor(level: 3, roll: 0.90),
      MorseSignalVariant.clean,
    );
  });
}
