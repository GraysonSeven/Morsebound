import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/game/reward_engine.dart';

void main() {
  test('wrong answers never score points', () {
    expect(
      RewardEngine.pointsFor(
        correct: false,
        perfect: false,
        reactionMs: 500,
        combo: 10,
        flowMode: true,
      ),
      0,
    );
  });

  test('fast perfect flow hit scores more than ordinary correct hit', () {
    final ordinary = RewardEngine.pointsFor(
      correct: true,
      perfect: false,
      reactionMs: 1200,
      combo: 1,
      flowMode: false,
    );

    final strong = RewardEngine.pointsFor(
      correct: true,
      perfect: true,
      reactionMs: 450,
      combo: 8,
      flowMode: true,
    );

    expect(strong, greaterThan(ordinary));
  });

  test('combo shortens only the between-signal pacing delay', () {
    final lowCombo = RewardEngine.pacingDelayMs(
      correct: true,
      combo: 1,
    );
    final highCombo = RewardEngine.pacingDelayMs(
      correct: true,
      combo: 10,
    );

    expect(highCombo, lessThan(lowCombo));
    expect(
      RewardEngine.pacingDelayMs(correct: false, combo: 10),
      900,
    );
  });

  test('mission grades reward both accuracy and automaticity', () {
    expect(
      RewardEngine.missionGrade(
        accuracy: 0.96,
        averageReactionMs: 700,
        bestCombo: 10,
      ),
      'S',
    );

    expect(
      RewardEngine.missionGrade(
        accuracy: 0.91,
        averageReactionMs: 1000,
        bestCombo: 6,
      ),
      'A',
    );

    expect(
      RewardEngine.missionGrade(
        accuracy: 0.84,
        averageReactionMs: 1600,
        bestCombo: 3,
      ),
      'B',
    );
  });
}
