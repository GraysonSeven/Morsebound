import 'dart:async';

import 'package:flutter/material.dart';

import '../learning/learning_model.dart';
import '../profile/career_profile.dart';
import '../profile/career_store.dart';
import '../release/app_update_service.dart';
import '../release/independent_update_service.dart';
import '../release/release_info.dart';
import '../settings/app_settings.dart';
import '../settings/settings_store.dart';
import '../storage/progress_store.dart';
import 'game_screen.dart';
import 'keying_lab_screen.dart';
import 'onboarding_screen.dart';
import 'progress_screen.dart';
import 'real_copy_screen.dart';
import 'settings_screen.dart';
import 'widgets/signal_backdrop.dart';
import 'word_rush_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final _progressStore = ProgressStore();
  final _careerStore = CareerStore();
  final _settingsStore = SettingsStore();
  final _updates = AppUpdateService.instance;
  final _independentUpdates = const IndependentUpdateService();

  LearningSnapshot? _learning;
  CareerProfile? _career;
  AppSettings? _settings;
  AppUpdateStatus? _updateStatus;
  IndependentUpdateStatus? _independentUpdateStatus;
  StreamSubscription<AppUpdateStatus>? _updateSubscription;

  Object? _loadError;
  bool _openingRoute = false;
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _updateSubscription = _updates.changes.listen((status) {
      if (!mounted) return;
      setState(() => _updateStatus = status);
    });

    _reload();
    _checkForUpdate();
    _checkIndependentUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
      _checkIndependentUpdate();
    }
  }

  Future<void> _checkIndependentUpdate() async {
    final status = await _independentUpdates.check();
    if (!mounted) return;
    setState(() => _independentUpdateStatus = status);
  }

  Future<void> _runIndependentUpdate() async {
    final status = _independentUpdateStatus;
    if (status == null || !status.actionable) return;
    final opened = await _independentUpdates.perform(status);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Public update link could not be opened.')),
    );
  }

  Future<void> _reload() async {
    try {
      final learning = await _progressStore
          .load()
          .timeout(const Duration(seconds: 5));
      final career = await _careerStore
          .load()
          .timeout(const Duration(seconds: 5));

      AppSettings? settings;
      try {
        settings = await _settingsStore
            .load()
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // Settings must never block the game home screen.
      }

      if (!mounted) return;
      setState(() {
        _learning = learning;
        _career = career;
        _settings = settings;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;

    _checkingUpdate = true;
    try {
      final status = await _updates.check();
      if (!mounted) return;
      setState(() => _updateStatus = status);
    } finally {
      _checkingUpdate = false;
    }
  }

  Future<void> _runUpdateAction() async {
    final status = _updateStatus;
    if (status == null) return;

    if (status.downloaded) {
      await _updates.completeUpdate();
      return;
    }

    if (!status.available || !status.flexibleAllowed) return;

    final started = await _updates.startFlexibleUpdate();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          started
              ? 'Update download started. Keep using Morsebound.'
              : 'Google Play could not start the update from this install.',
        ),
      ),
    );
  }

  Future<void> _open(Widget screen) async {
    if (_openingRoute) return;

    _openingRoute = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      );
      await _reload();
    } finally {
      _openingRoute = false;
    }
  }

  Future<void> _openOnboarding() async {
    if (_openingRoute) return;

    _openingRoute = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OnboardingScreen(
            onComplete: () => Navigator.of(context).pop(),
          ),
        ),
      );
      await _reload();
    } finally {
      _openingRoute = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final learning = _learning;
    final career = _career;

    return Scaffold(
      body: SignalBackdrop(
        child: SafeArea(
          child: _loadError != null
              ? _loadFailure()
              : learning == null || career == null
                  ? _startupShell()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 860;
                        final engine =
                            AdaptiveLearningEngine(snapshot: learning);

                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 38 : 16,
                            18,
                            wide ? 38 : 16,
                            34,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 1120),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _topBar(engine),
                                  if (_independentUpdateStatus?.actionable == true) ...[
                                    const SizedBox(height: 14),
                                    _independentUpdateBanner(_independentUpdateStatus!),
                                  ] else if (_updateStatus?.actionable == true) ...[
                                    const SizedBox(height: 14),
                                    _updateBanner(_updateStatus!),
                                  ],
                                  if (_settings?.onboardingComplete ==
                                      false) ...[
                                    const SizedBox(height: 14),
                                    _onboardingCard(),
                                  ],
                                  const SizedBox(height: 18),
                                  _heroMission(
                                    engine: engine,
                                    career: career,
                                    wide: wide,
                                  ),
                                  const SizedBox(height: 14),
                                  _careerStrip(
                                    career: career,
                                    engine: engine,
                                    wide: wide,
                                  ),
                                  const SizedBox(height: 26),
                                  _sectionHeading(
                                    'OPERATIONS',
                                    'Train receiving, sending, and real copy.',
                                  ),
                                  const SizedBox(height: 12),
                                  _operationsGrid(
                                    career: career,
                                    engine: engine,
                                    wide: wide,
                                  ),
                                  const SizedBox(height: 14),
                                  _progressAction(engine),
                                  const SizedBox(height: 30),
                                  const Center(
                                    child: Text(
                                      'Morsebound • iCharles\n'
                                      '${ReleaseInfo.creatorCredit}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.5,
                                        color: Color(0xFF8DA1A8),
                                      ),
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
      ),
    );
  }

  Widget _topBar(AdaptiveLearningEngine engine) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF55D6BE).withValues(alpha: 0.42),
            ),
            color: const Color(0xFF0D2229),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Color(0xFF8FFFEA),
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MORSEBOUND',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              Text(
                'SIGNAL OPS TRAINING SYSTEM',
                style: TextStyle(
                  color: Color(0xFF8DA1A8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Settings',
          onPressed: () => _open(const SettingsScreen()),
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }

  Widget _heroMission({
    required AdaptiveLearningEngine engine,
    required CareerProfile career,
    required bool wide,
  }) {
    final mastery = (engine.overallMastery * 100).round();
    final nextLine = engine.retentionDueCount > 0
        ? '${engine.retentionDueCount} retention signal'
            '${engine.retentionDueCount == 1 ? '' : 's'} due now'
        : 'Adaptive network training ready';

    return Container(
      padding: EdgeInsets.all(wide ? 26 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF12303A),
            Color(0xFF0B2027),
            Color(0xFF0A171D),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF55D6BE).withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: wide
          ? Row(
              children: [
                Expanded(child: _heroCopy(engine, mastery, nextLine)),
                const SizedBox(width: 24),
                SizedBox(
                  width: 260,
                  child: _primaryDeployButton(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heroCopy(engine, mastery, nextLine),
                const SizedBox(height: 18),
                _primaryDeployButton(),
              ],
            ),
    );
  }

  Widget _heroCopy(
    AdaptiveLearningEngine engine,
    int mastery,
    String nextLine,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _StatusDot(),
            const SizedBox(width: 8),
            Text(
              'COMMAND NETWORK ONLINE',
              style: TextStyle(
                color: const Color(0xFF8FFFEA).withValues(alpha: 0.92),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Continue Signal Ops',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          nextLine,
          style: const TextStyle(
            color: Color(0xFFB7C8CE),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: engine.overallMastery.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFF061218),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$mastery%',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF8FFFEA),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _primaryDeployButton() {
    return FilledButton.icon(
      onPressed: () => _open(const GameScreen()),
      icon: const Icon(Icons.cell_tower_rounded),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Text(
          'DEPLOY SIGNAL OPS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _careerStrip({
    required CareerProfile career,
    required AdaptiveLearningEngine engine,
    required bool wide,
  }) {
    final items = [
      ('RANK', engine.operatorRank, Icons.military_tech_rounded),
      ('SIGNALS', '${engine.unlocked.length}/36', Icons.hub_rounded),
      (
        'AUTOMATIC',
        '${engine.automaticCount}/${engine.unlocked.length}',
        Icons.bolt_rounded,
      ),
      (
        'STREAK',
        '${career.currentPracticeStreak}d',
        Icons.local_fire_department_rounded,
      ),
      ('BEST', '${career.bestScore}', Icons.workspace_premium_rounded),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          Container(
            width: wide ? 205 : 158,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1C22).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF41606A).withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.$3,
                  size: 19,
                  color: const Color(0xFF78CDBF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: Color(0xFF7F949B),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF82969D),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _operationsGrid({
    required CareerProfile career,
    required AdaptiveLearningEngine engine,
    required bool wide,
  }) {
    final unlocked = engine.unlocked.length;

    return GridView.count(
      crossAxisCount: wide ? 2 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: wide ? 2.75 : 2.55,
      children: [
        _modeCard(
          icon: Icons.cell_tower_rounded,
          title: 'Signal Ops',
          subtitle:
              'Adaptive network missions focused on your weakest and overdue signals.',
          tag: 'CORE',
          onTap: () => _open(const GameScreen()),
        ),
        _modeCard(
          icon: Icons.emergency_share_rounded,
          title: 'Daily Dispatch',
          subtitle:
              'A focused 12-signal operation built to protect long-term retention.',
          tag: career.dailyBestDay == _todayKey()
              ? 'BEST ${career.dailyBestScore}'
              : 'DAILY',
          onTap: () => _open(
            const GameScreen(
              missionTrialsTarget: 12,
              missionLabel: 'DAILY SPRINT',
              dailyChallenge: true,
            ),
          ),
        ),
        _modeCard(
          icon: Icons.hearing_rounded,
          title: 'Word Rush',
          subtitle: unlocked >= 8
              ? 'Move from character recognition into whole-word listening.'
              : 'Unlock 8 signals to enable whole-word recognition.',
          tag: unlocked >= 8 ? 'WORDS' : 'LOCKED',
          enabled: unlocked >= 8,
          onTap: () => _open(const WordRushScreen()),
        ),
        _modeCard(
          icon: Icons.touch_app_rounded,
          title: 'Keying Lab',
          subtitle:
              'Train sending mechanics with tap-for-dot and hold-for-dash input.',
          tag: 'SEND',
          onTap: () => _open(const KeyingLabScreen()),
        ),
        _modeCard(
          icon: Icons.radio_rounded,
          title: 'Real Copy',
          subtitle: unlocked >= 12
              ? 'Hear a transmission and type exactly what you copied.'
              : 'Unlock 12 signals to enable unrestricted typed receiving.',
          tag: unlocked >= 12 ? 'REAL' : 'LOCKED',
          enabled: unlocked >= 12,
          onTap: () => _open(const RealCopyScreen()),
        ),
        _modeCard(
          icon: Icons.analytics_outlined,
          title: 'Mastery Center',
          subtitle:
              'Review automatic signals, retention status, career, and achievements.',
          tag: 'PROGRESS',
          onTap: () => _open(const ProgressScreen()),
        ),
      ],
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Material(
      color: enabled
          ? const Color(0xFF0C2027).withValues(alpha: 0.94)
          : const Color(0xFF09161B).withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (enabled
                      ? const Color(0xFF4D747E)
                      : const Color(0xFF334249))
                  .withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xFF14343C)
                      : const Color(0xFF111D21),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  enabled ? icon : Icons.lock_outline_rounded,
                  color: enabled
                      ? const Color(0xFF78CDBF)
                      : const Color(0xFF65747A),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _MiniTag(tag: tag),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? const Color(0xFFA9BBC1)
                            : const Color(0xFF687A80),
                        height: 1.25,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                enabled
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_outline_rounded,
                size: 14,
                color: const Color(0xFF60747B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressAction(AdaptiveLearningEngine engine) {
    return OutlinedButton.icon(
      onPressed: () => _open(const ProgressScreen()),
      icon: const Icon(Icons.radar_rounded),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Text(
          '${engine.automaticCount} AUTOMATIC • '
          '${engine.retentionDueCount} DUE • OPEN MASTERY CENTER',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _independentUpdateBanner(IndependentUpdateStatus status) {
    final label = status.action == IndependentUpdateAction.refreshWeb
        ? 'REFRESH'
        : status.action == IndependentUpdateAction.openSamsungStore
            ? 'STORE'
            : 'DOWNLOAD';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102B31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF55D6BE).withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update_alt_rounded, color: Color(0xFF8FFFEA)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.message.isNotEmpty
                  ? status.message
                  : 'Morsebound ${status.latestVersion} is available.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: _runIndependentUpdate,
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _updateBanner(AppUpdateStatus status) {
    final ready = status.downloaded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102B31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF55D6BE).withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ready
                ? Icons.system_update_alt_rounded
                : Icons.downloading_rounded,
            color: const Color(0xFF8FFFEA),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ready
                  ? 'A Morsebound update is downloaded and ready to install.'
                  : 'A newer Morsebound release is available from Google Play.',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: _runUpdateAction,
            child: Text(ready ? 'INSTALL' : 'UPDATE'),
          ),
        ],
      ),
    );
  }

  Widget _onboardingCard() {
    return Material(
      color: const Color(0xFF102128),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openOnboarding,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: Color(0xFFFFD166),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'New to Morsebound? Take the short sound-first introduction.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _startupShell() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              size: 68,
              color: Color(0xFF8FFFEA),
            ),
            SizedBox(height: 16),
            Text(
              'MORSEBOUND',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(minHeight: 5),
            ),
            SizedBox(height: 12),
            Text(
              'Establishing command network...',
              style: TextStyle(color: Color(0xFF8DA1A8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadFailure() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 52,
                    color: Color(0xFFFFD166),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'MORSEBOUND COULD NOT LOAD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your saved data has not been erased. Retry the local '
                    'profile load.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_loadError',
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadError = null;
                        _learning = null;
                        _career = null;
                      });
                      _reload();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('RETRY'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF142B32),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFF8EA7AE),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF55D6BE),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x6655D6BE),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
