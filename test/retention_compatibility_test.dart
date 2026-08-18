import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/learning/learning_model.dart';

void main() {
  test('pre-V0.8 character save loads with retention defaults', () {
    final stats = CharacterStats.fromJson({
      'character': 'K',
      'exposures': 9,
      'correct': 8,
      'mastery': 0.77,
      'reactionEwmaMs': 900,
      'lastSeenMs': 1000,
      'dueAtMs': 2000,
      'correctStreak': 3,
      'lapses': 1,
    });

    expect(stats.retentionPasses, 0);
    expect(stats.retentionFails, 0);
    expect(stats.coldPasses, 0);
    expect(stats.coldFails, 0);
  });
}
