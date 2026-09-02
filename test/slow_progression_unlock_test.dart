import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/learning/learning_model.dart';

void main() {
  test('slow correct answers can unlock the next Koch character', () {
    var now = 50_000_000;
    final engine = AdaptiveLearningEngine(
      random: Random(141),
      nowMs: () => now,
    );

    for (var i = 0; i < 80 && engine.unlocked.length == 2; i++) {
      final target = i.isEven ? 'K' : 'M';
      engine.record(
        target: target,
        answer: target,
        reactionMs: 4200,
      );
      now += 1000;
    }

    expect(engine.unlocked.length, greaterThan(2));
    expect(engine.unlocked[2], 'R');

    // Proves unlock did not secretly depend on fast reaction time.
    expect(
      engine.snapshot.stats['K']!.reactionEwmaMs,
      greaterThan(3000),
    );
    expect(
      engine.snapshot.stats['M']!.reactionEwmaMs,
      greaterThan(3000),
    );
  });

  test('reaction speed still matters for automatic proficiency', () {
    final stats = CharacterStats(
      character: 'K',
      exposures: 20,
      correct: 20,
      mastery: 0.95,
      reactionEwmaMs: 4200,
      correctStreak: 8,
      retentionPasses: 4,
      coldPasses: 2,
    );

    expect(stats.proficiency, isNot(SignalProficiency.automatic));

    stats.reactionEwmaMs = 800;
    expect(stats.proficiency, SignalProficiency.automatic);
  });
}
