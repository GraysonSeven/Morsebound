import 'dart:math';

class RewardEngine {
  const RewardEngine._();

  static int pointsFor({
    required bool correct,
    required bool perfect,
    required int reactionMs,
    required int combo,
    required bool flowMode,
  }) {
    if (!correct) return 0;

    final clampedReaction = reactionMs.clamp(250, 2500);
    final speedBonus =
        (((2500 - clampedReaction) / 2250) * 120).round();
    final comboBonus = min(180, max(0, combo - 1) * 18);
    final perfectBonus = perfect ? 90 : 0;
    final flowBonus = flowMode ? 100 : 0;

    return 100 + speedBonus + comboBonus + perfectBonus + flowBonus;
  }

  static int pacingDelayMs({
    required bool correct,
    required int combo,
  }) {
    if (!correct) return 900;
    return max(180, 470 - (combo * 24));
  }

  static String missionGrade({
    required double accuracy,
    required int averageReactionMs,
    required int bestCombo,
  }) {
    if (accuracy >= 0.95 && averageReactionMs <= 800 && bestCombo >= 8) {
      return 'S';
    }
    if (accuracy >= 0.90 && averageReactionMs <= 1150 && bestCombo >= 5) {
      return 'A';
    }
    if (accuracy >= 0.82) return 'B';
    return 'C';
  }
}
