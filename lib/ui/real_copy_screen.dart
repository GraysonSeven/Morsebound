import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../learning/learning_model.dart';
import '../morse/morse_audio.dart';
import '../morse/morse_transfer.dart';
import '../profile/career_store.dart';
import '../settings/settings_store.dart';
import '../storage/progress_store.dart';
import '../training/copy_scoring.dart';
import '../training/word_bank.dart';

class RealCopyScreen extends StatefulWidget {
  const RealCopyScreen({super.key});

  @override
  State<RealCopyScreen> createState() => _RealCopyScreenState();
}

class _RealCopyScreenState extends State<RealCopyScreen> {
  static const _transmissionsPerRun = 5;

  final _progressStore = ProgressStore();
  final _careerStore = CareerStore();
  final _settingsStore = SettingsStore();
  final _audio = MorseAudio();
  final _random = Random();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<String> _wordPool = const [];
  int _characterGapMs = 420;
  int _wordGapMs = 900;
  int _transferLevel = 0;

  String? _target;
  bool _loading = true;
  bool _started = false;
  bool _audioPlaying = false;
  bool _needsGesture = false;
  bool _submitted = false;

  int _trial = 0;
  int _exact = 0;
  double _accuracyTotal = 0;
  String _feedback = 'No choices. Copy what you hear.';

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
      _wordPool = WordBank.eligible(unlocked);
      _characterGapMs = settings.wordCharacterGapMs;
      _wordGapMs = settings.realCopyWordGapMs;
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
      _exact = 0;
      _accuracyTotal = 0;
      _feedback = 'Listen...';
    });
    await _next(immediate: true);
  }

  String _newTransmission() {
    if (_wordPool.length < 2) return _wordPool.first;

    final first = _wordPool[_random.nextInt(_wordPool.length)];

    if (_wordPool.length < 8) return first;

    var second = _wordPool[_random.nextInt(_wordPool.length)];
    if (second == first) {
      final others = _wordPool.where((w) => w != first).toList();
      second = others[_random.nextInt(others.length)];
    }

    return '$first $second';
  }

  Future<void> _next({bool immediate = false}) async {
    if (_trial >= _transmissionsPerRun) return;

    final target = _newTransmission();
    _controller.clear();

    setState(() {
      _target = target;
      _submitted = false;
      _audioPlaying = true;
      _needsGesture = false;
      _feedback = 'Listen...';
    });

    if (!immediate) {
      await Future<void>.delayed(
        const Duration(milliseconds: 420),
      );
    }

    final played = await _audio.playText(
      target,
      interCharacterGapMs: _characterGapMs,
      wordGapMs: _wordGapMs,
      transferLevel: _transferLevel,
    );

    if (!mounted) return;

    if (!played) {
      setState(() {
        _audioPlaying = false;
        _needsGesture = true;
        _feedback = 'Tap PLAY TRANSMISSION to enable audio';
      });
      return;
    }

    setState(() {
      _audioPlaying = false;
      _needsGesture = false;
      _feedback = 'Type exactly what you copied';
    });

    _focusNode.requestFocus();
  }

  Future<void> _replay() async {
    final target = _target;
    if (target == null || _audioPlaying || _submitted) return;

    setState(() {
      _audioPlaying = true;
      _feedback = 'Replay...';
    });

    final played = await _audio.playText(
      target,
      interCharacterGapMs: _characterGapMs,
      wordGapMs: _wordGapMs,
      transferLevel: _transferLevel,
    );

    if (!mounted) return;

    setState(() {
      _audioPlaying = false;
      _needsGesture = !played;
      _feedback = played
          ? 'Type exactly what you copied'
          : 'Tap PLAY TRANSMISSION again';
    });

    if (played) _focusNode.requestFocus();
  }

  Future<void> _submit() async {
    final target = _target;
    if (target == null ||
        _submitted ||
        _audioPlaying ||
        _needsGesture) {
      return;
    }

    final actual = _controller.text;
    final accuracy = CopyScoring.accuracy(target, actual);
    final exact =
        CopyScoring.normalize(target) == CopyScoring.normalize(actual);

    _trial += 1;
    _accuracyTotal += accuracy;
    if (exact) _exact += 1;

    final career = await _careerStore.load();
    career.recordCopy(
      now: DateTime.now(),
      exact: exact,
      accuracy: accuracy,
    );
    await _careerStore.save(career);

    if (!mounted) return;
    setState(() {
      _submitted = true;
      _feedback = exact
          ? 'PERFECT COPY'
          : 'COPY ${(accuracy * 100).round()}% • $target';
    });

    await Future<void>.delayed(
      Duration(milliseconds: exact ? 650 : 1250),
    );

    if (!mounted || _trial >= _transmissionsPerRun) {
      setState(() {});
      return;
    }

    await _next();
  }

  @override
  void dispose() {
    unawaited(_audio.dispose());
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_wordPool.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('REAL COPY')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'Real Copy needs more unlocked characters. '
              'Keep training Adaptive Run first.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final complete =
        _started && _trial >= _transmissionsPerRun;

    return Scaffold(
      appBar: AppBar(title: const Text('REAL COPY')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: complete
                  ? _complete()
                  : !_started
                      ? _intro()
                      : _run(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radio, size: 66),
            const SizedBox(height: 16),
            const Text(
              'REAL COPY',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No multiple choice. Hear a transmission and type what you copied. '
              'As mastery grows, controlled field-radio variation is introduced '
              'so the skill transfers beyond one perfect tone.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('START REAL COPY'),
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
              '${min(_trial + 1, _transmissionsPerRun)}/'
              '$_transmissionsPerRun',
            ),
            const Spacer(),
            Text('EXACT $_exact'),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.graphic_eq, size: 72),
                    const SizedBox(height: 14),
                    Text(
                      _feedback,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    IconButton.filledTonal(
                      onPressed:
                          (_audioPlaying || _submitted) ? null : _replay,
                      tooltip: _needsGesture
                          ? 'Play transmission'
                          : 'Replay transmission',
                      icon: Icon(
                        _needsGesture
                            ? Icons.volume_up
                            : Icons.replay,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled:
              !_audioPlaying && !_needsGesture && !_submitted,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'What did you hear?',
            hintText: 'TYPE YOUR COPY',
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed:
              (_audioPlaying || _needsGesture || _submitted)
                  ? null
                  : _submit,
          icon: const Icon(Icons.check),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('SUBMIT COPY'),
          ),
        ),
      ],
    );
  }

  Widget _complete() {
    final avg = _trial == 0
        ? 0
        : (_accuracyTotal / _trial * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'COPY COMPLETE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$avg%',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Average copy accuracy • $_exact exact '
              'of $_transmissionsPerRun',
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.replay),
              label: const Text('COPY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}
