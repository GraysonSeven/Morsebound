import 'dart:math';

import '../morse/morse_code.dart';

enum SignalProficiency {
  weak,
  developing,
  relearning,
  automatic,
}

extension SignalProficiencyLabel on SignalProficiency {
  String get label {
    switch (this) {
      case SignalProficiency.weak:
        return 'WEAK';
      case SignalProficiency.developing:
        return 'DEVELOPING';
      case SignalProficiency.relearning:
        return 'RELEARNING';
      case SignalProficiency.automatic:
        return 'AUTOMATIC';
    }
  }

  String get shortLabel {
    switch (this) {
      case SignalProficiency.weak:
        return 'WEAK';
      case SignalProficiency.developing:
        return 'DEV';
      case SignalProficiency.relearning:
        return 'RELEARN';
      case SignalProficiency.automatic:
        return 'AUTO';
    }
  }
}

class CharacterStats {
  CharacterStats({
    required this.character,
    this.exposures = 0,
    this.correct = 0,
    this.mastery = 0.20,
    this.reactionEwmaMs = 1800,
    this.lastSeenMs = 0,
    this.dueAtMs = 0,
    this.correctStreak = 0,
    this.lapses = 0,
    this.retentionPasses = 0,
    this.retentionFails = 0,
    this.coldPasses = 0,
    this.coldFails = 0,
    this.lastRetentionMs = 0,
  });

  final String character;
  int exposures;
  int correct;
  double mastery;
  double reactionEwmaMs;
  int lastSeenMs;
  int dueAtMs;
  int correctStreak;
  int lapses;
  int retentionPasses;
  int retentionFails;
  int coldPasses;
  int coldFails;
  int lastRetentionMs;

  double get accuracy => exposures == 0 ? 0 : correct / exposures;
  int get retentionBalance => retentionPasses - retentionFails;
  int get coldBalance => coldPasses - coldFails;

  SignalProficiency get proficiency {
    if (exposures < 4 || mastery < 0.48) {
      return SignalProficiency.weak;
    }

    if (correctStreak == 0 && lapses > 0 && mastery < 0.72) {
      return SignalProficiency.relearning;
    }

    if (exposures >= 10 &&
        mastery >= 0.84 &&
        reactionEwmaMs <= 1000 &&
        retentionBalance >= 2 &&
        coldBalance >= 1 &&
        correctStreak >= 2) {
      return SignalProficiency.automatic;
    }

    if (mastery < 0.60 ||
        (exposures >= 6 && accuracy < 0.70)) {
      return SignalProficiency.weak;
    }

    return SignalProficiency.developing;
  }

  Map<String, dynamic> toJson() => {
        'character': character,
        'exposures': exposures,
        'correct': correct,
        'mastery': mastery,
        'reactionEwmaMs': reactionEwmaMs,
        'lastSeenMs': lastSeenMs,
        'dueAtMs': dueAtMs,
        'correctStreak': correctStreak,
        'lapses': lapses,
        'retentionPasses': retentionPasses,
        'retentionFails': retentionFails,
        'coldPasses': coldPasses,
        'coldFails': coldFails,
        'lastRetentionMs': lastRetentionMs,
      };

  factory CharacterStats.fromJson(Map<String, dynamic> json) => CharacterStats(
        character: json['character'] as String,
        exposures: (json['exposures'] as num?)?.toInt() ?? 0,
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        mastery: (json['mastery'] as num?)?.toDouble() ?? 0.20,
        reactionEwmaMs:
            (json['reactionEwmaMs'] as num?)?.toDouble() ?? 1800,
        lastSeenMs: (json['lastSeenMs'] as num?)?.toInt() ?? 0,
        dueAtMs: (json['dueAtMs'] as num?)?.toInt() ?? 0,
        correctStreak: (json['correctStreak'] as num?)?.toInt() ?? 0,
        lapses: (json['lapses'] as num?)?.toInt() ?? 0,
        retentionPasses:
            (json['retentionPasses'] as num?)?.toInt() ?? 0,
        retentionFails:
            (json['retentionFails'] as num?)?.toInt() ?? 0,
        coldPasses: (json['coldPasses'] as num?)?.toInt() ?? 0,
        coldFails: (json['coldFails'] as num?)?.toInt() ?? 0,
        lastRetentionMs:
            (json['lastRetentionMs'] as num?)?.toInt() ?? 0,
      );
}

class LearningSnapshot {
  LearningSnapshot({
    required this.unlockedCount,
    required this.totalTrials,
    required this.stats,
    required this.confusions,
  });

  int unlockedCount;
  int totalTrials;
  final Map<String, CharacterStats> stats;
  final Map<String, int> confusions;

  Map<String, dynamic> toJson() => {
        'unlockedCount': unlockedCount,
        'totalTrials': totalTrials,
        'stats': stats.map((k, v) => MapEntry(k, v.toJson())),
        'confusions': confusions,
      };

  factory LearningSnapshot.fresh() {
    final stats = <String, CharacterStats>{
      for (final c in MorseCode.learningOrder) c: CharacterStats(character: c),
    };

    return LearningSnapshot(
      unlockedCount: 2,
      totalTrials: 0,
      stats: stats,
      confusions: <String, int>{},
    );
  }

  factory LearningSnapshot.fromJson(Map<String, dynamic> json) {
    final fresh = LearningSnapshot.fresh();

    final rawStats = json['stats'];
    if (rawStats is Map) {
      for (final entry in rawStats.entries) {
        if (entry.value is Map) {
          fresh.stats[entry.key.toString()] = CharacterStats.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    final rawConfusions = json['confusions'];
    if (rawConfusions is Map) {
      for (final entry in rawConfusions.entries) {
        fresh.confusions[entry.key.toString()] =
            (entry.value as num).toInt();
      }
    }

    fresh.unlockedCount = min(
      MorseCode.learningOrder.length,
      max(2, (json['unlockedCount'] as num?)?.toInt() ?? 2),
    );
    fresh.totalTrials = (json['totalTrials'] as num?)?.toInt() ?? 0;

    return fresh;
  }
}

class LearningOutcome {
  const LearningOutcome({
    required this.correct,
    required this.perfect,
    required this.masteryBefore,
    required this.masteryAfter,
    required this.unlockedCharacter,
    required this.retentionTest,
    required this.coldTest,
  });

  final bool correct;
  final bool perfect;
  final double masteryBefore;
  final double masteryAfter;
  final String? unlockedCharacter;
  final bool retentionTest;
  final bool coldTest;
}

class AdaptiveLearningEngine {
  AdaptiveLearningEngine({
    LearningSnapshot? snapshot,
    Random? random,
    int Function()? nowMs,
  })  : snapshot = snapshot ?? LearningSnapshot.fresh(),
        _random = random ?? Random(),
        _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final LearningSnapshot snapshot;
  final Random _random;
  final int Function() _nowMs;

  String? _lastTarget;
  int _sinceRetentionProbe = 0;

  List<String> get unlocked => MorseCode.learningOrder
      .take(snapshot.unlockedCount)
      .toList(growable: false);

  int get automaticCount => unlocked
      .where(
        (c) =>
            snapshot.stats[c]!.proficiency ==
            SignalProficiency.automatic,
      )
      .length;

  int get retentionDueCount {
    final now = _nowMs();
    return unlocked.where((c) {
      final due = snapshot.stats[c]!.dueAtMs;
      return due > 0 && now >= due;
    }).length;
  }

  String get operatorRank {
    final auto = automaticCount;
    final breadth = snapshot.unlockedCount;

    if (breadth >= 36 && auto >= 32) return 'Master Operator';
    if (breadth >= 30 && auto >= 26) return 'Senior Operator';
    if (breadth >= 20 && auto >= 16) return 'Radio Operator';
    if (breadth >= 12 && auto >= 8) return 'Signal Operator';
    if (breadth >= 5 && auto >= 2) return 'Cadet';
    return 'Recruit';
  }

  int get operatorRankLevel {
    switch (operatorRank) {
      case 'Master Operator':
        return 6;
      case 'Senior Operator':
        return 5;
      case 'Radio Operator':
        return 4;
      case 'Signal Operator':
        return 3;
      case 'Cadet':
        return 2;
      default:
        return 1;
    }
  }

  String selectNext() {
    final pool = unlocked;
    final now = _nowMs();

    final duePool = pool.where((c) {
      final due = snapshot.stats[c]!.dueAtMs;
      return due > 0 && now >= due;
    }).toList(growable: false);

    if (duePool.isNotEmpty && _sinceRetentionProbe >= 4) {
      final selected = _weightedChoice(duePool, now);
      _lastTarget = selected;
      _sinceRetentionProbe = 0;
      return selected;
    }

    final selected = _weightedChoice(pool, now);
    final selectedStats = snapshot.stats[selected]!;
    final selectedWasDue =
        selectedStats.dueAtMs > 0 && now >= selectedStats.dueAtMs;

    if (selectedWasDue) {
      _sinceRetentionProbe = 0;
    } else {
      _sinceRetentionProbe += 1;
    }

    _lastTarget = selected;
    return selected;
  }

  String _weightedChoice(List<String> pool, int now) {
    final candidates = <({String character, double weight})>[];

    for (final c in pool) {
      final s = snapshot.stats[c]!;
      final due = s.dueAtMs > 0 && now >= s.dueAtMs;
      final unseenMs =
          s.lastSeenMs == 0 ? 0 : max(0, now - s.lastSeenMs);

      final newSignal = s.exposures < 6 ? 1.25 : 0.0;
      final weakness =
          (1.08 - s.mastery).clamp(0.08, 1.08).toDouble();
      final slow =
          ((s.reactionEwmaMs - 500) / 1700).clamp(0.0, 0.70).toDouble();

      final overdue = due
          ? (0.80 +
                  ((now - s.dueAtMs) / 3600000.0)
                      .clamp(0.0, 1.20))
              .toDouble()
          : 0.0;

      final coldPressure =
          unseenMs >= 2 * 60 * 60 * 1000 && s.mastery >= 0.60
              ? 1.10
              : 0.0;

      final lapsePressure = min(0.80, s.lapses * 0.10);
      final confusionPressure = _confusionPressure(c);

      var weight = weakness +
          slow +
          newSignal +
          overdue +
          coldPressure +
          lapsePressure +
          confusionPressure;

      if (s.proficiency == SignalProficiency.automatic && !due) {
        weight *= 0.55;
      }

      if (_lastTarget == c &&
          pool.length > 1 &&
          !due &&
          s.mastery >= 0.55) {
        weight *= 0.28;
      }

      candidates.add((
        character: c,
        weight: max(0.05, weight).toDouble(),
      ));
    }

    final total =
        candidates.fold<double>(0, (sum, item) => sum + item.weight);

    var roll = _random.nextDouble() * total;
    for (final candidate in candidates) {
      roll -= candidate.weight;
      if (roll <= 0) return candidate.character;
    }

    return candidates.last.character;
  }

  double _confusionPressure(String character) {
    var total = 0;

    for (final entry in snapshot.confusions.entries) {
      final parts = entry.key.split('>');
      if (parts.length != 2) continue;

      if (parts[0] == character || parts[1] == character) {
        total += entry.value;
      }
    }

    return min(1.10, total * 0.14).toDouble();
  }

  List<String> choicesFor(String target, {int maxChoices = 4}) {
    final pool = unlocked.toList();
    final desired = min(maxChoices, pool.length);
    final choices = <String>{target};
    final confusionScores = <String, int>{};

    for (final entry in snapshot.confusions.entries) {
      final parts = entry.key.split('>');
      if (parts.length != 2) continue;

      final source = parts[0];
      final answer = parts[1];

      if (source == target && pool.contains(answer)) {
        confusionScores[answer] =
            (confusionScores[answer] ?? 0) + entry.value * 2;
      } else if (answer == target && pool.contains(source)) {
        confusionScores[source] =
            (confusionScores[source] ?? 0) + entry.value;
      }
    }

    final ranked = confusionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in ranked) {
      choices.add(entry.key);
      if (choices.length >= desired) break;
    }

    pool.shuffle(_random);
    for (final c in pool) {
      choices.add(c);
      if (choices.length >= desired) break;
    }

    final result = choices.toList()..shuffle(_random);
    return result;
  }

  LearningOutcome record({
    required String target,
    required String answer,
    required int reactionMs,
  }) {
    final now = _nowMs();
    final stats = snapshot.stats[target]!;

    final before = stats.mastery;
    final previousSeenMs = stats.lastSeenMs;
    final dueBefore = stats.dueAtMs;

    final retentionTest = dueBefore > 0 && now >= dueBefore;
    final unseenMs =
        previousSeenMs == 0 ? 0 : max(0, now - previousSeenMs);
    final coldTest =
        retentionTest && unseenMs >= 2 * 60 * 60 * 1000;

    final isCorrect = target == answer;
    final reaction = reactionMs.clamp(100, 5000).toDouble();

    stats.exposures += 1;
    snapshot.totalTrials += 1;
    stats.lastSeenMs = now;

    stats.reactionEwmaMs = stats.exposures == 1
        ? reaction
        : (stats.reactionEwmaMs * 0.78) + (reaction * 0.22);

    if (isCorrect) {
      stats.correct += 1;
      stats.correctStreak += 1;

      if (retentionTest) {
        stats.retentionPasses += 1;
        stats.lastRetentionMs = now;
      }

      if (coldTest) {
        stats.coldPasses += 1;
      }

      final speedScore =
          ((2100 - reaction) / 1600).clamp(0.0, 1.0).toDouble();

      final evidence = 0.58 + (0.42 * speedScore);
      final spacingFactor = _spacingFactor(
        previousSeenMs: previousSeenMs,
        now: now,
        wasDue: retentionTest,
      );

      final gainRate = 0.18 * spacingFactor;
      stats.mastery = (stats.mastery +
              ((evidence - stats.mastery) * gainRate))
          .clamp(0.0, 1.0)
          .toDouble();

      if (retentionTest) {
        final retentionBonus = coldTest ? 0.055 : 0.030;
        stats.mastery = (stats.mastery +
                retentionBonus * (0.45 + 0.55 * speedScore))
            .clamp(0.0, 1.0)
            .toDouble();
      }

      if (reaction <= 1300) {
        _resolveOneConfusion(target);
      }

      final intervalMinutes = _retentionIntervalMinutes(stats);
      stats.dueAtMs = now + intervalMinutes * 60 * 1000;
    } else {
      stats.correctStreak = 0;
      stats.lapses += 1;

      if (retentionTest) {
        stats.retentionFails += 1;
        stats.lastRetentionMs = now;
      }

      if (coldTest) {
        stats.coldFails += 1;
      }

      final multiplier = coldTest
          ? 0.55
          : retentionTest
              ? 0.62
              : 0.72;

      stats.mastery =
          (stats.mastery * multiplier).clamp(0.0, 1.0).toDouble();
      stats.dueAtMs = now + 2 * 60 * 1000;

      final key = '$target>$answer';
      final pressure = retentionTest ? 2 : 1;
      snapshot.confusions[key] =
          (snapshot.confusions[key] ?? 0) + pressure;
    }

    final beforeUnlockCount = snapshot.unlockedCount;
    _maybeUnlock();

    final String? unlockedCharacter =
        snapshot.unlockedCount > beforeUnlockCount
            ? MorseCode.learningOrder[snapshot.unlockedCount - 1]
            : null;

    return LearningOutcome(
      correct: isCorrect,
      perfect: isCorrect && reaction <= 550,
      masteryBefore: before,
      masteryAfter: stats.mastery,
      unlockedCharacter: unlockedCharacter,
      retentionTest: retentionTest,
      coldTest: coldTest,
    );
  }

  double _spacingFactor({
    required int previousSeenMs,
    required int now,
    required bool wasDue,
  }) {
    if (previousSeenMs == 0) return 0.70;
    if (wasDue) return 1.0;

    final elapsed = max(0, now - previousSeenMs);

    if (elapsed >= 2 * 60 * 60 * 1000) return 0.95;
    if (elapsed >= 30 * 60 * 1000) return 0.85;
    if (elapsed >= 5 * 60 * 1000) return 0.72;
    if (elapsed >= 90 * 1000) return 0.55;
    return 0.38;
  }

  void _resolveOneConfusion(String target) {
    MapEntry<String, int>? strongest;

    for (final entry in snapshot.confusions.entries) {
      if (!entry.key.startsWith('$target>') || entry.value <= 0) {
        continue;
      }

      if (strongest == null || entry.value > strongest.value) {
        strongest = entry;
      }
    }

    if (strongest == null) return;

    final next = strongest.value - 1;
    if (next <= 0) {
      snapshot.confusions.remove(strongest.key);
    } else {
      snapshot.confusions[strongest.key] = next;
    }
  }

  int _retentionIntervalMinutes(CharacterStats stats) {
    final verified = stats.retentionBalance;
    final coldVerified = stats.coldBalance;

    if (stats.mastery >= 0.93 &&
        verified >= 4 &&
        coldVerified >= 2 &&
        stats.correctStreak >= 4) {
      return 7 * 24 * 60;
    }

    if (stats.mastery >= 0.90 &&
        verified >= 3 &&
        coldVerified >= 1 &&
        stats.correctStreak >= 4) {
      return 3 * 24 * 60;
    }

    if (stats.mastery >= 0.86 &&
        verified >= 2 &&
        stats.correctStreak >= 4) {
      return 24 * 60;
    }

    if (stats.mastery >= 0.80 && stats.correctStreak >= 4) {
      return 8 * 60;
    }

    if (stats.mastery >= 0.72 && stats.correctStreak >= 3) {
      return 2 * 60;
    }

    if (stats.correctStreak >= 2) return 30;
    return 8;
  }

  void _maybeUnlock() {
    if (snapshot.unlockedCount >= MorseCode.learningOrder.length) return;

    final pool = unlocked;

    if (snapshot.totalTrials < pool.length * 12) return;

    final weakestExposures =
        pool.map((c) => snapshot.stats[c]!.exposures).reduce(min);
    if (weakestExposures < 6) return;

    final accuracy = pool
            .map((c) => snapshot.stats[c]!.accuracy)
            .fold<double>(0, (a, b) => a + b) /
        pool.length;

    final weakestAccuracy =
        pool.map((c) => snapshot.stats[c]!.accuracy).reduce(min);

    final avgMastery = pool
            .map((c) => snapshot.stats[c]!.mastery)
            .fold<double>(0, (a, b) => a + b) /
        pool.length;

    final weakestMastery =
        pool.map((c) => snapshot.stats[c]!.mastery).reduce(min);

    final avgReaction = pool
            .map((c) => snapshot.stats[c]!.reactionEwmaMs)
            .fold<double>(0, (a, b) => a + b) /
        pool.length;

    if (accuracy >= 0.88 &&
        weakestAccuracy >= 0.72 &&
        avgMastery >= 0.74 &&
        weakestMastery >= 0.62 &&
        avgReaction <= 1450) {
      snapshot.unlockedCount += 1;
    }
  }

  List<String> weakest({int count = 3}) {
    final list = unlocked.toList()
      ..sort((a, b) {
        final sa = snapshot.stats[a]!;
        final sb = snapshot.stats[b]!;
        final confusionA = _confusionPressure(a);
        final confusionB = _confusionPressure(b);

        final scoreA = sa.mastery -
            (sa.lapses * 0.04) -
            (sa.retentionFails * 0.05) -
            (confusionA * 0.08);

        final scoreB = sb.mastery -
            (sb.lapses * 0.04) -
            (sb.retentionFails * 0.05) -
            (confusionB * 0.08);

        return scoreA.compareTo(scoreB);
      });

    return list.take(min(count, list.length)).toList(growable: false);
  }

  String? strongestConfusion() {
    final entries = snapshot.confusions.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.isEmpty ? null : entries.first.key;
  }

  SignalProficiency proficiencyFor(String character) =>
      snapshot.stats[character]!.proficiency;

  double get overallMastery {
    final pool = unlocked;
    if (pool.isEmpty) return 0;

    return pool
            .map((c) => snapshot.stats[c]!.mastery)
            .fold<double>(0, (a, b) => a + b) /
        pool.length;
  }
}
