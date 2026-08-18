import 'package:flutter/material.dart';

import '../learning/learning_model.dart';
import '../morse/morse_code.dart';
import '../profile/career_profile.dart';
import '../profile/career_store.dart';
import '../storage/progress_store.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _progressStore = ProgressStore();
  final _careerStore = CareerStore();

  LearningSnapshot? _learning;
  CareerProfile? _career;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final learning = await _progressStore.load();
    final career = await _careerStore.load();
    if (!mounted) return;

    setState(() {
      _learning = learning;
      _career = career;
    });
  }

  @override
  Widget build(BuildContext context) {
    final learning = _learning;
    final career = _career;

    final engine = learning == null
        ? null
        : AdaptiveLearningEngine(snapshot: learning);

    return Scaffold(
      appBar: AppBar(title: const Text('MORSEBOUND PROGRESS')),
      body: learning == null || career == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _rankCard(career, learning, engine!),
                      const SizedBox(height: 14),
                      _careerCard(career, learning, engine),
                      const SizedBox(height: 14),
                      _achievementCard(career, learning, engine),
                      const SizedBox(height: 18),
                      const Text(
                        'SIGNAL MASTERY',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount:
                            MediaQuery.sizeOf(context).width >= 760
                                ? 8
                                : 6,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 7,
                        mainAxisSpacing: 7,
                        children: [
                          for (var i = 0;
                              i < MorseCode.learningOrder.length;
                              i++)
                            _signalTile(
                              learning,
                              engine,
                              MorseCode.learningOrder[i],
                              i < learning.unlockedCount,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _rankCard(
    CareerProfile career,
    LearningSnapshot learning,
    AdaptiveLearningEngine engine,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              child: Text(
                '${engine.operatorRankLevel}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    engine.operatorRank.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${learning.unlockedCount}/36 unlocked • '
                    '${engine.automaticCount} automatic • '
                    '${engine.retentionDueCount} due • '
                    '${career.currentPracticeStreak} day streak',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _careerCard(
    CareerProfile career,
    LearningSnapshot learning,
    AdaptiveLearningEngine engine,
  ) {
    final accuracy = (career.lifetimeAccuracy * 100).round();
    final wordAccuracy = career.wordsTried == 0
        ? 0
        : (career.wordsCorrect / career.wordsTried * 100).round();
    final sendAccuracy = career.sendsTried == 0
        ? 0
        : (career.sendsCorrect / career.sendsTried * 100).round();
    final copyAccuracy =
        (career.averageCopyAccuracy * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 28,
          runSpacing: 16,
          children: [
            _metric('MISSIONS', '${career.missionsCompleted}'),
            _metric(
              'AUTOMATIC',
              '${engine.automaticCount}/${learning.unlockedCount}',
            ),
            _metric('RECEIVE', '$accuracy%'),
            _metric('WORD COPY', '$wordAccuracy%'),
            _metric('SEND', '$sendAccuracy%'),
            _metric('REAL COPY', '$copyAccuracy%'),
            _metric('BEST SCORE', '${career.bestScore}'),
            _metric('BEST CHAIN', '×${career.bestCombo}'),
            _metric('PERFECTS', '${career.perfects}'),
            _metric('BEST STREAK', '${career.bestPracticeStreak}d'),
          ],
        ),
      ),
    );
  }

  Widget _achievementCard(
    CareerProfile career,
    LearningSnapshot learning,
    AdaptiveLearningEngine engine,
  ) {
    final coldVerified = engine.unlocked.fold<int>(
      0,
      (sum, character) =>
          sum + learning.stats[character]!.coldPasses,
    );

    final achievements = <(String, bool)>[
      ('First Contact', career.missionsCompleted >= 1),
      ('Flow State', career.bestCombo >= 8),
      ('Clean Copy', career.bestMissionAccuracy >= 0.999),
      ('Word Reader', career.wordsCorrect >= 25),
      ('Morse Keyer', career.sendsCorrect >= 25),
      ('Real Copy', career.copyTried >= 10 &&
          career.averageCopyAccuracy >= 0.80),
      ('Cold Copy', coldVerified >= 10),
      ('Verified Operator', engine.automaticCount >= 8),
      ('Alphabet Online', learning.unlockedCount >= 26),
      ('Full Spectrum', learning.unlockedCount >= 36),
      ('Seven Day Signal', career.bestPracticeStreak >= 7),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACHIEVEMENTS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final achievement in achievements)
                  Chip(
                    avatar: Icon(
                      achievement.$2
                          ? Icons.verified
                          : Icons.lock_outline,
                      size: 17,
                    ),
                    label: Text(achievement.$1),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 125,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalTile(
    LearningSnapshot learning,
    AdaptiveLearningEngine engine,
    String character,
    bool unlocked,
  ) {
    final stats = learning.stats[character];
    final mastery =
        stats == null ? 0 : (stats.mastery * 100).round();
    final proficiency = unlocked
        ? engine.proficiencyFor(character)
        : SignalProficiency.weak;

    return Tooltip(
      message: unlocked
          ? '$character • ${proficiency.label} • $mastery% mastery • '
              '${stats?.reactionEwmaMs.round() ?? 0} ms • '
              '${stats?.retentionPasses ?? 0} retention passes • '
              '${stats?.coldPasses ?? 0} cold passes'
          : '$character • locked',
      child: Card(
        margin: EdgeInsets.zero,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                unlocked ? character : '•',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: unlocked ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                unlocked ? proficiency.shortLabel : 'LOCK',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (unlocked)
                Text(
                  '$mastery%',
                  style: const TextStyle(fontSize: 8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
