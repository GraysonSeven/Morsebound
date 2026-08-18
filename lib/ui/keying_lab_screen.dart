import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../learning/learning_model.dart';
import '../morse/morse_code.dart';
import '../profile/career_store.dart';
import '../storage/progress_store.dart';

class KeyingLabScreen extends StatefulWidget {
  const KeyingLabScreen({super.key});

  @override
  State<KeyingLabScreen> createState() => _KeyingLabScreenState();
}

class _KeyingLabScreenState extends State<KeyingLabScreen> {
  final _progressStore = ProgressStore();
  final _careerStore = CareerStore();
  final _random = Random();

  AdaptiveLearningEngine? _engine;
  String? _target;
  String _entered = '';
  bool _evaluating = false;
  int _correct = 0;
  int _trials = 0;
  int _combo = 0;
  int _bestCombo = 0;
  String _feedback = 'Tap = dot • Hold = dash';
  Stopwatch? _pressClock;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _progressStore.load();
    if (!mounted) return;

    setState(() {
      _engine = AdaptiveLearningEngine(
        snapshot: snapshot,
        random: _random,
      );
    });
    _next();
  }

  void _next() {
    final engine = _engine;
    if (engine == null) return;

    setState(() {
      _target = engine.selectNext();
      _entered = '';
      _evaluating = false;
      _feedback = 'Tap = dot • Hold = dash';
    });
  }

  void _keyDown(TapDownDetails details) {
    if (_evaluating) return;
    _pressClock = Stopwatch()..start();
  }

  void _keyCancel() {
    _pressClock?.stop();
    _pressClock = null;
  }

  Future<void> _keyUp(TapUpDetails details) async {
    final target = _target;
    final clock = _pressClock;

    if (target == null || clock == null || _evaluating) return;

    clock.stop();
    _pressClock = null;

    final symbol = clock.elapsedMilliseconds < 260 ? '.' : '-';
    final expected = MorseCode.patternFor(target);

    setState(() {
      _entered += symbol;
    });

    if (symbol == '.') {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
    }

    if (_entered.length >= expected.length) {
      await _evaluate();
    }
  }

  Future<void> _evaluate() async {
    final target = _target;
    if (target == null || _evaluating) return;

    final expected = MorseCode.patternFor(target);
    final correct = _entered == expected;

    setState(() {
      _evaluating = true;
      _trials += 1;
      if (correct) {
        _correct += 1;
        _combo += 1;
        _bestCombo = max(_bestCombo, _combo);
        _feedback = 'CLEAN SEND';
      } else {
        _combo = 0;
        _feedback =
            'Correct: ${expected.replaceAll('.', '·')}';
      }
    });

    final career = await _careerStore.load();
    career.recordSend(
      now: DateTime.now(),
      correct: correct,
    );
    await _careerStore.save(career);

    if (!mounted) return;
    await Future<void>.delayed(
      Duration(milliseconds: correct ? 620 : 1100),
    );
    if (mounted) _next();
  }

  void _clear() {
    if (_evaluating) return;
    setState(() {
      _entered = '';
      _feedback = 'Cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;

    return Scaffold(
      appBar: AppBar(title: const Text('KEYING LAB')),
      body: SafeArea(
        child: target == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'ACCURACY ${_trials == 0 ? 0 : (_correct / _trials * 100).round()}%',
                            ),
                            const Spacer(),
                            Text('CHAIN ×$_combo'),
                            const SizedBox(width: 16),
                            Text('BEST ×$_bestCombo'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Card(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'SEND',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      target,
                                      style: const TextStyle(
                                        fontSize: 82,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _entered.isEmpty
                                          ? '• • •'
                                          : _entered
                                              .replaceAll('.', '·')
                                              .replaceAll('-', '—'),
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _feedback,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: _keyDown,
                          onTapUp: _keyUp,
                          onTapCancel: _keyCancel,
                          child: Container(
                            height: 104,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.radio_button_checked, size: 36),
                                SizedBox(height: 4),
                                Text(
                                  'MORSE KEY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text('tap • hold'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _evaluating ? null : _clear,
                          icon: const Icon(Icons.backspace_outlined),
                          label: const Text('CLEAR SEND'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
