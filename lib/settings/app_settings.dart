class AppSettings {
  AppSettings({
    this.onboardingComplete = false,
    this.wordCharacterGapMs = 420,
    this.realCopyWordGapMs = 900,
    this.transferTrainingEnabled = true,
  });

  bool onboardingComplete;
  int wordCharacterGapMs;
  int realCopyWordGapMs;
  bool transferTrainingEnabled;

  String get pacingLabel {
    if (wordCharacterGapMs >= 520) return 'Comfort';
    if (wordCharacterGapMs <= 320) return 'Fast';
    return 'Standard';
  }

  void applyPacingPreset(String preset) {
    switch (preset) {
      case 'Comfort':
        wordCharacterGapMs = 560;
        realCopyWordGapMs = 1050;
      case 'Fast':
        wordCharacterGapMs = 300;
        realCopyWordGapMs = 700;
      default:
        wordCharacterGapMs = 420;
        realCopyWordGapMs = 900;
    }
  }

  Map<String, dynamic> toJson() => {
        'onboardingComplete': onboardingComplete,
        'wordCharacterGapMs': wordCharacterGapMs,
        'realCopyWordGapMs': realCopyWordGapMs,
        'transferTrainingEnabled': transferTrainingEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        onboardingComplete:
            json['onboardingComplete'] as bool? ?? false,
        wordCharacterGapMs:
            (json['wordCharacterGapMs'] as num?)?.toInt() ?? 420,
        realCopyWordGapMs:
            (json['realCopyWordGapMs'] as num?)?.toInt() ?? 900,
        transferTrainingEnabled:
            json['transferTrainingEnabled'] as bool? ?? true,
      );
}
