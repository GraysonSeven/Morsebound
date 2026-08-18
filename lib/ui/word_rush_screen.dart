import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../learning/learning_model.dart';
import '../morse/morse_audio.dart';
import '../morse/morse_transfer.dart';
import '../profile/career_store.dart';
import '../settings/settings_store.dart';
import '../storage/progress_store.dart';
import '../training/word_bank.dart';

class WordRushScreen extends StatefulWidget {
  const WordRushScreen({super.key});

  @override
  State<WordRushScreen> createState() => _WordRushScreenState();
}

class _WordRushScreenState extends State<WordRushScreen> {
  static const _trialsPerRun = 10;

  final _progressStore = ProgressStore();
  final _careerStore = CareerStore();
  final _settingsStore = SettingsStore();
  final _audio = MorseAudio();
  final _random = Random();

  List<String> _pool = const [];
  int _characterGapMs = 420;
  int _transferLevel = 0;
  String? _target;
  List<String> _choices = const [];
  bool _loading = true;
  bool _started = false;
  bool _audioPlaying = false;
  bool _needsGesture = false;
  bool _answered = true;
  int _trial = 0;
  int _correct = 0;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  String _feedback = 'Whole words become sound patterns.';
  Stopwatch? _reaction;
  String? _lastTarget;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final learning = await _progressStore.load();
    final settings = await _settingsStore.load();
    final engine = AdaptiveLearningEngine(snapshot: learning);
    final unlocked = learning.stats.keys
        .take(learning.unlockedCount)
        .toSet();

    if (!mounted) return;
    setState(() {
      _pool = WordBank.eligible(unlocked);
      _characterGapMs = settings.wordCharacterGapMs;
      _transferLevel = MorseTransferProfile.levelFor(
        unlockedCount: learning.unlockedCount,
        overallMastery: engine.overallMastery,
        enabled: settings.transferTrainingEnabled,
      );
      _loading = false;
    });
  }

  Future<void> _start() async {
    setState(() {
      _started = true;
      _trial = 0;
      _correct = 0;
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _feedback = 'Listen to the whole word...';
    });
    await _next(immediate: true);
  }

  Future<void> _next({bool immediate = false}) async {
    if (_trial >= _trialsPerRun) {
      setState(() {
        _answered = true;
        _feedback = 'RUN COMPLETE';
      });
      return;
    }

    if (_pool.length < 2) return;

    var target = _pool[_random.nextInt(_pool.length)];
    if (_pool.length > 1 && target == _lastTarget) {
      final alternatives =
          _pool.where((value) => value != target).toList();
      target = alternatives[_random.nextInt(alternatives.length)];
    }
    _lastTarget = target;

    setState(() {
      _target = target;
      _choices = WordBank.choices(
        target: target,
        pool: _pool,
        random: _random,
      );
      _answered = false;
      _audioPlaying = true;
      _needsGesture = false;
      _feedback = 'Listen...';
    });

    if (!immediate) {
      await Future<void>.delayed(
        Duration(
          milliseconds: max(170, 360 - (_combo * 18)).toInt(),
        ),
      );
    }

    final played = await _audio.playText(
      target,
      interCharacterGapMs:
          max(230, _characterGapMs - (_combo * 12)).toInt(),
      transferLevel: _transferLevel,
    );

    if (!mounted) return;

    if (!played) {
      setState(() {
        _audioPlaying = false;
        _needsGesture = true;
        _feedback = 'Tap PLAY WORD to enable audio';
      });
      return;
    }

    _reaction = Stopwatch()..start();
    setState(() {
      _audioPlaying = false;
      _needsGesture = false;
      _feedback = 'Recognize the word';
    });
  }

  Future<void> _replay() async {
    final target = _target;
    if (target == null || _audioPlaying || _answered) return;

    setState(() {
      _audioPlaying = true;
      _feedback = 'Replay...';
    });

    final played = await _audio.playText(
      target,
      interCharacterGapMs: _characterGapMs,
      transferLevel: _transferLevel,
    );
    if (!mounted) return;

    if (!played) {
      setState(() {
        _audioPlaying = false;
        _needsGesture = true;
        _feedback = 'Tap PLAY WORD again';
      });
      return;
    }

    _reaction = Stopwatch()..start();
    setState(() {
      _audioPlaying = false;
      _needsGesture = false;
      _feedback = 'Recognize the word';
    });
  }

  Future<void> _answer(String answer) async {
    final target = _target;
    if (target == null ||
        _answered ||
        _audioPlaying ||
        _needsGesture ||
        _trial >= _trialsPerRun) {
      return;
    }

    _reaction?.stop();
    final reactionMs = _reaction?.elapsedMilliseconds ?? 3000;
    final correct = answer == target;

    _trial += 1;

    if (correct) {
      _correct += 1;
      _combo += 1;
      _bestCombo = max(_bestCombo, _combo);
      final speedBonus =
          max(0, 1800 - reactionMs).toInt() ~/ 12;
      final comboBonus = min(150, _combo * 18).toInt();
      _score += 150 + speedBonus + comboBonus;
    } else {
      _combo = 0;
    }

    final career = await _careerStore.load();
    career.recordWord(
      now: DateTime.now(),
      correct: correct,
    );
    await _careerStore.save(career);

    if (!mounted) return;
    setState(() {
      _answered = true;
      _feedback = correct
          ? 'WORD LOCKED  ${reactionMs}ms'
          : 'WORD WAS $target';
    });

    await Future<void>.delayed(
      Duration(milliseconds: correct ? 520 : 1000),
    );
    if (mounted) await _next();
  }


  @override
  void dispose() {
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pool.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('WORD RUSH')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'Word Rush needs more unlocked characters. '
              'Keep playing Adaptive Run first.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final complete = _started && _trial >= _trialsPerRun;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WORD RUSH'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: complete
                  ? _completeCard()
                  : !_started
                      ? _introCard()
                      : _run(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _introCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hearing, size: 60),
            const SizedBox(height: 16),
            const Text(
              'HEAR THE WORD — NOT THE LETTERS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_pool.length} words are currently available from '
              'your unlocked signals.'
              '${_transferLevel > 0 ? ' Field-signal variation is active.' : ''}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('START WORD RUSH'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _run() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${min(_trial + 1, _trialsPerRun)}/$_trialsPerRun',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text('×$_combo'),
            const SizedBox(width: 18),
            Text('$_score'),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.graphic_eq, size: 72),
                    const SizedBox(height: 16),
                    Text(
                      _feedback,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    IconButton.filledTonal(
                      onPressed:
                          (_audioPlaying || _answered) ? null : _replay,
                      icon: Icon(
                        _needsGesture
                            ? Icons.volume_up
                            : Icons.replay,
                      ),
                      tooltip:
                          _needsGesture ? 'Play word' : 'Replay word',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.7,
          children: [
            for (final word in _choices)
              FilledButton.tonal(
                onPressed:
                    (_audioPlaying || _needsGesture || _answered)
                        ? null
                        : () => _answer(word),
                child: Text(
                  word,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _completeCard() {
    final accuracy = (_correct / _trialsPerRun * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'WORD RUSH COMPLETE',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$accuracy%',
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text('Score $_score • Best chain ×$_bestCombo'),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.replay),
              label: const Text('RUN AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}
