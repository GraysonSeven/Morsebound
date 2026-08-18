import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/reward_engine.dart';
import '../game/signal_ops_mission.dart';
import '../game/signal_runner_game.dart';
import '../learning/learning_model.dart';
import '../morse/morse_audio.dart';
import '../morse/morse_transfer.dart';
import '../settings/settings_store.dart';
import '../profile/career_store.dart';
import '../storage/progress_store.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.missionTrialsTarget = 24,
    this.missionLabel = 'ADAPTIVE RUN',
    this.dailyChallenge = false,
  });

  final int missionTrialsTarget;
  final String missionLabel;
  final bool dailyChallenge;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _MissionSummary {
  const _MissionSummary({
    required this.trials,
    required this.correct,
    required this.averageReactionMs,
    required this.masteryDelta,
    required this.weakest,
    required this.strongestConfusion,
    required this.unlocked,
    required this.score,
    required this.bestCombo,
    required this.perfects,
    required this.grade,
  });

  final int trials;
  final int correct;
  final int averageReactionMs;
  final double masteryDelta;
  final List<String> weakest;
  final String? strongestConfusion;
  final List<String> unlocked;
  final int score;
  final int bestCombo;
  final int perfects;
  final String grade;

  double get accuracy => trials == 0 ? 0 : correct / trials;
}

class _GameScreenState extends State<GameScreen> {
  static const int _flowTurns = 6;

  final _game = SignalRunnerGame();
  final _audio = MorseAudio();
  final _store = ProgressStore();
  final _careerStore = CareerStore();
  final _settingsStore = SettingsStore();
  final _transferRandom = Random();

  AdaptiveLearningEngine? _engine;
  String? _target;
  List<String> _choices = const [];

  bool _started = false;
  bool _audioPlaying = false;
  bool _audioNeedsGesture = false;
  bool _answered = true;
  bool _gameOver = false;
  bool _missionComplete = false;
  bool _disposed = false;
  bool _transferTrainingEnabled = true;
  MorseSignalVariant _signalVariant = MorseSignalVariant.clean;

  Stopwatch? _reactionClock;

  int _combo = 0;
  int _bestCombo = 0;
  int _score = 0;
  int _perfects = 0;
  int _missionRetentionChecks = 0;
  int _missionColdVerified = 0;
  double _flowCharge = 0;
  int _flowTurnsRemaining = 0;

  String _feedback = 'Headphones on. Restore the network by sound.';

  int _missionTrials = 0;
  int _missionCorrect = 0;
  int _missionReactionTotalMs = 0;
  double _missionStartMastery = 0;
  final List<String> _missionUnlocks = [];
  _MissionSummary? _summary;

  bool get _flowMode => _flowTurnsRemaining > 0;

  @override
  void initState() {
    super.initState();
    _game.battle.addListener(_battleChanged);
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _store.load();

    var transferTrainingEnabled = true;
    try {
      final settings = await _settingsStore.load();
      transferTrainingEnabled = settings.transferTrainingEnabled;
    } catch (_) {
      // Transfer training must never block the core learning game.
    }

    if (!mounted) return;
    setState(() {
      _engine = AdaptiveLearningEngine(snapshot: snapshot);
      _transferTrainingEnabled = transferTrainingEnabled;
    });
  }

  int get _transferLevel {
    final engine = _engine;
    if (engine == null) return 0;

    return MorseTransferProfile.levelFor(
      unlockedCount: engine.snapshot.unlockedCount,
      overallMastery: engine.overallMastery,
      enabled: _transferTrainingEnabled,
    );
  }

  void _battleChanged() {
    if (!mounted) return;
    final battle = _game.battle.value;
    if (battle.lives <= 0 && !_gameOver) {
      setState(() {
        _gameOver = true;
        _answered = true;
        _feedback = 'NETWORK INTEGRITY LOST • operation ended';
      });
      _finishMission();
    } else {
      setState(() {});
    }
  }

  Future<void> _start() async {
    final engine = _engine;
    if (engine == null) return;

    setState(() {
      _started = true;
      _gameOver = false;
      _missionComplete = false;
      _summary = null;

      _combo = 0;
      _bestCombo = 0;
      _score = 0;
      _perfects = 0;
      _missionRetentionChecks = 0;
      _missionColdVerified = 0;
      _flowCharge = 0;
      _flowTurnsRemaining = 0;
      _audioNeedsGesture = false;

      _feedback = 'Listen...';
      _missionTrials = 0;
      _missionCorrect = 0;
      _missionReactionTotalMs = 0;
      _missionStartMastery = engine.overallMastery;
      _missionUnlocks.clear();
    });

    _game.restartBattle();
    await _nextTrial(immediateAudio: true);
  }

  Future<void> _nextTrial({bool immediateAudio = false}) async {
    if (_disposed ||
        _gameOver ||
        _missionComplete ||
        _engine == null ||
        _missionTrials >= widget.missionTrialsTarget) {
      if (!_gameOver && !_missionComplete) {
        _finishMission();
      }
      return;
    }

    final target = _engine!.selectNext();
    final choices = _engine!.choicesFor(target);
    final signalVariant = MorseTransferProfile.variantFor(
      level: _transferLevel,
      roll: _transferRandom.nextDouble(),
    );

    setState(() {
      _target = target;
      _signalVariant = signalVariant;
      _choices = choices;
      _answered = false;
      _audioPlaying = true;
      _feedback = _flowMode ? 'FLOW • Listen...' : 'Listen...';
    });

    if (!immediateAudio) {
      final preSignalDelay =
          _flowMode ? 150 : max(175, 260 - (_combo * 6));
      await Future<void>.delayed(Duration(milliseconds: preSignalDelay));
      if (_disposed || _gameOver || _missionComplete) return;
    }

    final played = await _audio.playCharacter(
      target,
      variant: _signalVariant,
    );
    if (_disposed || !mounted || _gameOver || _missionComplete) return;

    if (!played) {
      setState(() {
        _audioPlaying = false;
        _audioNeedsGesture = true;
        _feedback = 'Tap PLAY SIGNAL to enable audio';
      });
      return;
    }

    _reactionClock = Stopwatch()..start();
    setState(() {
      _audioPlaying = false;
      _audioNeedsGesture = false;
      _feedback = _flowMode ? 'FLOW • Identify' : 'Identify the signal';
    });
  }

  Future<void> _replay() async {
    final target = _target;
    if (target == null ||
        _audioPlaying ||
        _answered ||
        _gameOver ||
        _missionComplete) {
      return;
    }

    _reactionClock?.stop();
    setState(() {
      _audioPlaying = true;
      _feedback = _audioNeedsGesture ? 'Enabling audio...' : 'Replay...';
    });

    final played = await _audio.playCharacter(
      target,
      variant: _signalVariant,
    );
    if (!mounted || _gameOver || _missionComplete) return;

    if (!played) {
      setState(() {
        _audioPlaying = false;
        _audioNeedsGesture = true;
        _feedback = 'Audio is blocked — tap PLAY SIGNAL again';
      });
      return;
    }

    _reactionClock = Stopwatch()..start();
    setState(() {
      _audioPlaying = false;
      _audioNeedsGesture = false;
      _feedback = _flowMode ? 'FLOW • Identify' : 'Identify the signal';
    });
  }

  Future<void> _answer(String answer) async {
    final target = _target;
    final engine = _engine;

    if (target == null ||
        engine == null ||
        _answered ||
        _audioPlaying ||
        _audioNeedsGesture ||
        _gameOver ||
        _missionComplete) {
      return;
    }

    _reactionClock?.stop();
    final reaction = _reactionClock?.elapsedMilliseconds ?? 2500;
    final wasFlowMode = _flowMode;

    setState(() => _answered = true);

    final outcome = engine.record(
      target: target,
      answer: answer,
      reactionMs: reaction,
    );

    _missionTrials += 1;
    _missionReactionTotalMs += reaction;

    if (outcome.retentionTest) {
      _missionRetentionChecks += 1;
    }
    if (outcome.correct && outcome.coldTest) {
      _missionColdVerified += 1;
    }

    if (outcome.correct) {
      _missionCorrect += 1;
      _combo += 1;
      _bestCombo = max(_bestCombo, _combo);

      if (outcome.perfect) _perfects += 1;

      _score += RewardEngine.pointsFor(
        correct: true,
        perfect: outcome.perfect,
        reactionMs: reaction,
        combo: _combo,
        flowMode: wasFlowMode,
      );

      if (wasFlowMode) {
        _flowTurnsRemaining = max(0, _flowTurnsRemaining - 1);
        _flowCharge = (_flowTurnsRemaining / _flowTurns) * 100;
      } else {
        _flowCharge = min(
          100,
          _flowCharge + (outcome.perfect ? 22 : 13),
        ).toDouble();

        if (_flowCharge >= 100) {
          _flowTurnsRemaining = _flowTurns;
        }
      }

      _game.correct(
        perfect: outcome.perfect,
        flowMode: wasFlowMode || _flowTurnsRemaining > 0,
        combo: _combo,
      );
    } else {
      _combo = 0;
      _flowCharge = 0;
      _flowTurnsRemaining = 0;
      _game.wrong();
    }

    if (outcome.unlockedCharacter != null &&
        !_missionUnlocks.contains(outcome.unlockedCharacter)) {
      _missionUnlocks.add(outcome.unlockedCharacter!);
    }

    await _store.save(engine.snapshot);
    if (!mounted) return;

    setState(() {
      if (outcome.unlockedCharacter != null) {
        _feedback = 'NEW SIGNAL ${outcome.unlockedCharacter} UNLOCKED';
      } else if (!outcome.correct && outcome.coldTest) {
        _feedback = 'COLD LAPSE • SIGNAL WAS $target';
      } else if (!outcome.correct && outcome.retentionTest) {
        _feedback = 'RETENTION LAPSE • SIGNAL WAS $target';
      } else if (!outcome.correct) {
        _feedback = 'SIGNAL WAS $target • INTERFERENCE ADVANCING';
      } else if (outcome.coldTest) {
        _feedback = 'COLD COPY VERIFIED • ${reaction}ms';
      } else if (outcome.retentionTest) {
        _feedback = 'RETENTION VERIFIED • ${reaction}ms';
      } else if (_flowMode && !wasFlowMode) {
        _feedback = 'HIGH-BANDWIDTH LINK ONLINE';
      } else if (wasFlowMode) {
        _feedback = outcome.perfect
            ? 'FLOW LOCK • ${reaction}ms'
            : 'FLOW LINK • ${reaction}ms';
      } else if (_combo == 10) {
        _feedback = 'NETWORK SURGE ×10';
      } else if (_combo == 5) {
        _feedback = 'STABLE LINK ×5';
      } else if (_combo == 3) {
        _feedback = 'LINK CHAIN ×3';
      } else {
        _feedback = outcome.perfect
            ? 'RELAY LOCK • ${reaction}ms'
            : 'LINK STABLE • ${reaction}ms';
      }
    });

    if (outcome.correct) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.heavyImpact();
    }

    if (_missionTrials >= widget.missionTrialsTarget) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      _finishMission();
      return;
    }

    if (_game.battle.value.lives <= 0) return;

    await Future<void>.delayed(
      Duration(
        milliseconds: RewardEngine.pacingDelayMs(
          correct: outcome.correct,
          combo: _combo,
        ),
      ),
    );

    await _nextTrial();
  }

  void _finishMission() {
    final engine = _engine;
    if (engine == null || _missionComplete) return;

    final avgReaction = _missionTrials == 0
        ? 0
        : (_missionReactionTotalMs / _missionTrials).round();

    final accuracy =
        _missionTrials == 0 ? 0.0 : _missionCorrect / _missionTrials;

    unawaited(_recordCareerMission(
      trials: _missionTrials,
      correct: _missionCorrect,
      score: _score,
      bestCombo: _bestCombo,
      perfects: _perfects,
    ));

    setState(() {
      _missionComplete = true;
      _answered = true;
      _summary = _MissionSummary(
        trials: _missionTrials,
        correct: _missionCorrect,
        averageReactionMs: avgReaction,
        masteryDelta: engine.overallMastery - _missionStartMastery,
        weakest: engine.weakest(),
        strongestConfusion: engine.strongestConfusion(),
        unlocked: List<String>.from(_missionUnlocks),
        score: _score,
        bestCombo: _bestCombo,
        perfects: _perfects,
        grade: RewardEngine.missionGrade(
          accuracy: accuracy,
          averageReactionMs: avgReaction,
          bestCombo: _bestCombo,
        ),
      );
      _feedback = 'Mission complete';
    });
  }

  Future<void> _recordCareerMission({
    required int trials,
    required int correct,
    required int score,
    required int bestCombo,
    required int perfects,
  }) async {
    final profile = await _careerStore.load();
    profile.recordMission(
      now: DateTime.now(),
      trials: trials,
      correct: correct,
      score: score,
      bestComboInMission: bestCombo,
      perfectsInMission: perfects,
      daily: widget.dailyChallenge,
    );
    await _careerStore.save(profile);
  }

  Future<void> _resetLearning() async {
    await _store.reset();
    if (!mounted) return;

    setState(() {
      _engine = AdaptiveLearningEngine();
      _started = false;
      _gameOver = false;
      _missionComplete = false;
      _summary = null;

      _combo = 0;
      _bestCombo = 0;
      _score = 0;
      _perfects = 0;
      _missionRetentionChecks = 0;
      _missionColdVerified = 0;
      _flowCharge = 0;
      _flowTurnsRemaining = 0;
      _audioNeedsGesture = false;

      _target = null;
      _choices = const [];
      _feedback = 'Learning profile reset.';
    });

    _game.restartBattle();
  }

  @override
  void dispose() {
    _disposed = true;
    _game.battle.removeListener(_battleChanged);
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    final battle = _game.battle.value;

    return Scaffold(
      body: SafeArea(
        child: engine == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  return Column(
                    children: [
                      _hud(engine, battle),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                GameWidget(game: _game),
                                if (!_started) _startOverlay(engine),
                                if (_missionComplete) _summaryOverlay(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_started && !_missionComplete)
                        _controls(engine, wide: wide),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _hud(AdaptiveLearningEngine engine, BattleSnapshot battle) {
    final mastery = (engine.overallMastery * 100).round();
    final missionProgress =
        '${min(_missionTrials, widget.missionTrialsTarget)}/${widget.missionTrialsTarget}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Back to Morsebound',
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Text(
                widget.dailyChallenge
                    ? 'MORSEBOUND • DAILY'
                    : 'MORSEBOUND • ${widget.missionLabel}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                ),
              ),
              const Spacer(),
              if (_started) ...[
                Text(
                  '${SignalOpsMission.phaseFor(
                    completed: _missionTrials,
                    total: widget.missionTrialsTarget,
                  )} • $missionProgress',
                ),
                const SizedBox(width: 12),
              ],
              Text('NET ${battle.networkIntegrity}/3'),
              const SizedBox(width: 12),
              Text('RELAYS ${battle.relaysRestored}'),
              if (_transferLevel > 0) ...[
                const SizedBox(width: 12),
                Text(MorseTransferProfile.levelLabel(_transferLevel)),
              ],
              const SizedBox(width: 12),
              Text('×$_combo'),
              const SizedBox(width: 12),
              Text('$_score'),
              const SizedBox(width: 12),
              Text(
                '${engine.unlocked.length} SIG • $mastery% • '
                'AUTO ${engine.automaticCount}',
              ),
              PopupMenuButton<String>(
                tooltip: 'Options',
                onSelected: (value) {
                  if (value == 'reset') _resetLearning();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'reset',
                    child: Text('Reset learning profile'),
                  ),
                ],
              ),
            ],
          ),
          if (_started && !_missionComplete) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  _flowMode ? 'FLOW' : 'FLOW CHARGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _flowMode ? const Color(0xFF9FFFEF) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_flowCharge / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                  ),
                ),
                if (_flowMode) ...[
                  const SizedBox(width: 10),
                  Text(
                    '$_flowTurnsRemaining',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _startOverlay(AdaptiveLearningEngine engine) {
    return ColoredBox(
      color: const Color(0xDD071117),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq, size: 64),
                const SizedBox(height: 16),
                Text(
                  SignalOpsMission.operationName(
                    daily: widget.dailyChallenge,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'by iCharles — Charles Leanne S. Lioc',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'HEAR. RECOGNIZE. REACT.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Restore up to ${SignalOpsMission.relayGoalFor(widget.missionTrialsTarget)} '
                  'relay links across ${widget.missionTrialsTarget} adaptive transmissions. '
                  'Correct recognition stabilizes the network. Misreads push '
                  'interference toward command. FLOW opens a high-bandwidth link. '
                  'As mastery rises, field-signal variation activates automatically.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('DEPLOY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryOverlay() {
    final summary = _summary;
    if (summary == null) return const SizedBox.shrink();

    final accuracyPct = (summary.accuracy * 100).round();
    final masteryDeltaPct = (summary.masteryDelta * 100).round();
    final confusion = summary.strongestConfusion?.replaceAll('>', ' → ');

    return ColoredBox(
      color: const Color(0xE6080C11),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      summary.grade,
                      style: const TextStyle(
                        fontSize: 58,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'OPERATION COMPLETE',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _summaryRow('Score', '${summary.score}'),
                    _summaryRow(
                      'Relays restored',
                      '${_game.battle.value.relaysRestored}',
                    ),
                    _summaryRow('Accuracy', '$accuracyPct%'),
                    _summaryRow(
                      'Average reaction',
                      '${summary.averageReactionMs} ms',
                    ),
                    _summaryRow('Best combo', '×${summary.bestCombo}'),
                    _summaryRow('Perfects', '${summary.perfects}'),
                    _summaryRow(
                      'Retention checks',
                      '$_missionRetentionChecks',
                    ),
                    _summaryRow(
                      'Cold verified',
                      '$_missionColdVerified',
                    ),
                    _summaryRow(
                      'Mastery change',
                      '${masteryDeltaPct >= 0 ? '+' : ''}$masteryDeltaPct%',
                    ),
                    _summaryRow(
                      'Weakest signals',
                      summary.weakest.join('  '),
                    ),
                    if (confusion != null)
                      _summaryRow('Top confusion', confusion),
                    if (summary.unlocked.isNotEmpty)
                      _summaryRow(
                        'New signals',
                        summary.unlocked.join('  '),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      accuracyPct >= 92
                          ? 'Strong recognition. Next mission will lean harder on automaticity and retention.'
                          : accuracyPct >= 82
                              ? 'Good learning pressure. Weak signals stay in rotation.'
                              : 'Accuracy comes first. The engine will reinforce weak signals before increasing difficulty.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.replay),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('NEXT OPERATION'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _controls(AdaptiveLearningEngine engine, {required bool wide}) {
    final targetStats =
        _target == null ? null : engine.snapshot.stats[_target!];
    final mastery =
        targetStats == null ? 0 : (targetStats.mastery * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: (_audioPlaying || _answered) ? null : _replay,
                  tooltip:
                      _audioNeedsGesture ? 'Play signal' : 'Replay signal',
                  icon: Icon(
                    _audioNeedsGesture ? Icons.volume_up : Icons.replay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _feedback,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: _flowMode ? const Color(0xFF9FFFEF) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: Text(
                    _target == null ? '' : '$mastery%',
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount:
                  wide ? _choices.length.clamp(2, 4) : 2,
              childAspectRatio: wide ? 2.8 : 2.25,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final character in _choices)
                  FilledButton.tonal(
                    onPressed:
                        (_audioPlaying || _audioNeedsGesture || _answered)
                            ? null
                            : () => _answer(character),
                    child: Text(
                      character,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
