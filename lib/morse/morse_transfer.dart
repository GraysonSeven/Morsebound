enum MorseSignalVariant {
  clean,
  lowPitch,
  highPitch,
  radio,
}

class MorseTransferProfile {
  const MorseTransferProfile._();

  static int levelFor({
    required int unlockedCount,
    required double overallMastery,
    required bool enabled,
  }) {
    if (!enabled) return 0;
    if (unlockedCount < 12 || overallMastery < 0.45) return 0;
    if (unlockedCount < 20 || overallMastery < 0.60) return 1;
    if (unlockedCount < 30 || overallMastery < 0.72) return 2;
    return 3;
  }

  /// [roll] must be in the range 0 <= roll < 1.
  ///
  /// The clean signal remains in the mix at every level so transfer
  /// training never becomes a separate memorization task.
  static MorseSignalVariant variantFor({
    required int level,
    required double roll,
  }) {
    final r = roll.clamp(0.0, 0.999999);

    switch (level) {
      case 1:
        if (r < 0.10) return MorseSignalVariant.lowPitch;
        if (r < 0.20) return MorseSignalVariant.highPitch;
        return MorseSignalVariant.clean;

      case 2:
        if (r < 0.18) return MorseSignalVariant.lowPitch;
        if (r < 0.36) return MorseSignalVariant.highPitch;
        if (r < 0.46) return MorseSignalVariant.radio;
        return MorseSignalVariant.clean;

      case 3:
        if (r < 0.27) return MorseSignalVariant.lowPitch;
        if (r < 0.54) return MorseSignalVariant.highPitch;
        if (r < 0.78) return MorseSignalVariant.radio;
        return MorseSignalVariant.clean;

      default:
        return MorseSignalVariant.clean;
    }
  }

  static String levelLabel(int level) {
    switch (level) {
      case 1:
        return 'FIELD I';
      case 2:
        return 'FIELD II';
      case 3:
        return 'REAL RADIO';
      default:
        return 'CLEAN';
    }
  }
}
