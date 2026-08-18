import 'package:flutter/material.dart';

import '../settings/settings_store.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPageData {
  const _OnboardingPageData(
    this.icon,
    this.title,
    this.body,
  );

  final IconData icon;
  final String title;
  final String body;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _store = SettingsStore();
  int _page = 0;
  bool _saving = false;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      Icons.hearing,
      'LEARN THE SOUND',
      'Morsebound trains the sound pattern directly. '
          'Do not count dots and dashes in your head.',
    ),
    _OnboardingPageData(
      Icons.psychology_alt,
      'ADAPTIVE TRAINING',
      'Weak, slow, confused, and overdue signals return more often. '
          'Strong signals get spaced out.',
    ),
    _OnboardingPageData(
      Icons.bolt,
      'ACCURACY BEFORE SPEED',
      'Fast recognition earns score and FLOW, but new signals unlock only '
          'when your accuracy shows the skill is stable.',
    ),
    _OnboardingPageData(
      Icons.radio,
      'FROM GAME TO REAL MORSE',
      'Adaptive Run builds characters. Word Rush builds chunks. '
          'Keying Lab trains sending. Real Copy removes multiple choice.',
    ),
  ];

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final settings = await _store.load();
      settings.onboardingComplete = true;
      await _store.save(settings);
    } catch (_) {
      // Onboarding persistence is useful, but must never trap the user.
    }

    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MORSEBOUND INTRO'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _finish,
            child: const Text('SKIP'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) =>
                    setState(() => _page = value),
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 620),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(page.icon, size: 82),
                            const SizedBox(height: 24),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              page.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Row(
                children: [
                  Text('${_page + 1}/${_pages.length}'),
                  const SizedBox(width: 14),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_page + 1) / _pages.length,
                    ),
                  ),
                  const SizedBox(width: 14),
                  FilledButton.icon(
                    onPressed: _saving
                        ? null
                        : _page == _pages.length - 1
                            ? _finish
                            : () => _controller.nextPage(
                                  duration: const Duration(
                                    milliseconds: 220,
                                  ),
                                  curve: Curves.easeOut,
                                ),
                    icon: Icon(
                      _page == _pages.length - 1
                          ? Icons.play_arrow
                          : Icons.chevron_right,
                    ),
                    label: Text(
                      _page == _pages.length - 1
                          ? 'DONE'
                          : 'NEXT',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
