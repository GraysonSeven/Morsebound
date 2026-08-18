import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/learning/learning_model.dart';

void main() {
  test('fresh profile starts with K and M only', () {
    final engine = AdaptiveLearningEngine(random: Random(1));
    expect(engine.unlocked, ['K', 'M']);
  });

  test('selection never leaves unlocked pool', () {
    final engine = AdaptiveLearningEngine(random: Random(2));
    for (var i = 0; i < 100; i++) {
      expect(['K', 'M'], contains(engine.selectNext()));
    }
  });

  test('wrong answer creates confusion and near-term retry', () {
    const now = 1_000_000;
    final engine = AdaptiveLearningEngine(
      random: Random(3),
      nowMs: () => now,
    );

    final outcome = engine.record(
      target: 'K',
      answer: 'M',
      reactionMs: 900,
    );

    expect(outcome.correct, isFalse);
    expect(engine.snapshot.confusions['K>M'], 1);
    expect(engine.snapshot.stats['K']!.lapses, 1);
    expect(
      engine.snapshot.stats['K']!.dueAtMs,
      now + 2 * 60 * 1000,
    );
  });

  test('strong focused performance can still unlock Koch progression', () {
    var now = 3_000_000;
    final engine = AdaptiveLearningEngine(
      random: Random(5),
      nowMs: () => now,
    );

    for (var i = 0; i < 60 && engine.unlocked.length == 2; i++) {
      final target = i.isEven ? 'K' : 'M';
      engine.record(
        target: target,
        answer: target,
        reactionMs: 380,
      );
      now += 1000;
    }

    expect(engine.unlocked.length, greaterThan(2));
    expect(engine.unlocked[2], 'R');
  });

  test('spaced evidence raises mastery faster than rapid drilling', () {
    var rapidNow = 10_000_000;
    var spacedNow = 10_000_000;

    final rapid = AdaptiveLearningEngine(
      random: Random(6),
      nowMs: () => rapidNow,
    );
    final spaced = AdaptiveLearningEngine(
      random: Random(6),
      nowMs: () => spacedNow,
    );

    for (var i = 0; i < 6; i++) {
      rapid.record(target: 'K', answer: 'K', reactionMs: 420);
      rapidNow += 1000;

      spaced.record(target: 'K', answer: 'K', reactionMs: 420);
      spacedNow += 10 * 60 * 1000;
    }

    expect(
      spaced.snapshot.stats['K']!.mastery,
      greaterThan(rapid.snapshot.stats['K']!.mastery),
    );
    expect(
      spaced.snapshot.stats['K']!.retentionPasses,
      greaterThan(0),
    );
  });

  test('cold correct answer verifies retention', () {
    const now = 20_000_000;
    final snapshot = LearningSnapshot.fresh();
    final stats = snapshot.stats['K']!;

    stats.exposures = 12;
    stats.correct = 11;
    stats.mastery = 0.82;
    stats.reactionEwmaMs = 780;
    stats.correctStreak = 3;
    stats.lastSeenMs = now - 3 * 60 * 60 * 1000;
    stats.dueAtMs = now - 60 * 1000;

    final engine = AdaptiveLearningEngine(
      snapshot: snapshot,
      random: Random(7),
      nowMs: () => now,
    );

    final outcome =
        engine.record(target: 'K', answer: 'K', reactionMs: 500);

    expect(outcome.retentionTest, isTrue);
    expect(outcome.coldTest, isTrue);
    expect(stats.retentionPasses, 1);
    expect(stats.coldPasses, 1);
  });

  test('cold lapse causes relearning pressure', () {
    const now = 30_000_000;
    final snapshot = LearningSnapshot.fresh();
    final stats = snapshot.stats['K']!;

    stats.exposures = 20;
    stats.correct = 19;
    stats.mastery = 0.90;
    stats.reactionEwmaMs = 700;
    stats.correctStreak = 5;
    stats.retentionPasses = 3;
    stats.coldPasses = 2;
    stats.lastSeenMs = now - 4 * 60 * 60 * 1000;
    stats.dueAtMs = now - 1000;

    final engine = AdaptiveLearningEngine(
      snapshot: snapshot,
      random: Random(8),
      nowMs: () => now,
    );

    final outcome =
        engine.record(target: 'K', answer: 'M', reactionMs: 900);

    expect(outcome.coldTest, isTrue);
    expect(stats.mastery, lessThan(0.55));
    expect(stats.retentionFails, 1);
    expect(stats.coldFails, 1);
    expect(stats.proficiency, SignalProficiency.relearning);
  });

  test('fast correct evidence resolves confusion debt', () {
    final snapshot = LearningSnapshot.fresh();
    snapshot.confusions['K>M'] = 3;

    final engine = AdaptiveLearningEngine(
      snapshot: snapshot,
      random: Random(9),
      nowMs: () => 40_000_000,
    );

    engine.record(target: 'K', answer: 'K', reactionMs: 600);
    expect(snapshot.confusions['K>M'], 2);
  });

  test('automatic requires verified cold retention', () {
    final stats = CharacterStats(
      character: 'K',
      exposures: 18,
      correct: 17,
      mastery: 0.90,
      reactionEwmaMs: 780,
      correctStreak: 4,
      retentionPasses: 3,
      coldPasses: 1,
    );

    expect(stats.proficiency, SignalProficiency.automatic);

    stats.coldPasses = 0;
    expect(stats.proficiency, SignalProficiency.developing);
  });

  test('operator rank is based on verified automatic signals', () {
    final snapshot = LearningSnapshot.fresh();
    snapshot.unlockedCount = 12;

    for (final character in snapshot.stats.keys.take(8)) {
      final stats = snapshot.stats[character]!;
      stats.exposures = 20;
      stats.correct = 19;
      stats.mastery = 0.90;
      stats.reactionEwmaMs = 750;
      stats.correctStreak = 5;
      stats.retentionPasses = 3;
      stats.coldPasses = 1;
    }

    final engine = AdaptiveLearningEngine(
      snapshot: snapshot,
      random: Random(10),
    );

    expect(engine.automaticCount, 8);
    expect(engine.operatorRank, 'Signal Operator');
  });
}
