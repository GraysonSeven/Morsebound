
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../learning/learning_model.dart';
import '../profile/career_profile.dart';
import '../profile/career_store.dart';
import '../release/app_update_service.dart';
import '../release/independent_update_service.dart';
import '../release/release_info.dart';
import '../settings/app_settings.dart';
import '../settings/settings_store.dart';
import '../storage/backup_codec.dart';
import '../storage/progress_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsStore = SettingsStore();
  final _progressStore = ProgressStore();
  final _careerStore = CareerStore();
  final _updates = AppUpdateService.instance;
  final _independentUpdates = const IndependentUpdateService();

  AppSettings? _settings;
  AppUpdateStatus? _updateStatus;
  IndependentUpdateStatus? _independentUpdateStatus;
  bool _checkingForUpdate = false;

  @override
  void initState() {
    super.initState();
    _load();
    _checkForUpdate();
    _checkIndependentUpdate();
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

  Future<void> _checkForUpdate() async {
    if (_checkingForUpdate) return;

    _checkingForUpdate = true;
    try {
      final status = await _updates.check();
      if (!mounted) return;
      setState(() => _updateStatus = status);
    } finally {
      _checkingForUpdate = false;
    }
  }

  Future<void> _startUpdate() async {
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
              ? 'Update download started through Google Play.'
              : 'No Play update could be started from this install.',
        ),
      ),
    );
  }

  Future<void> _load() async {
    final settings = await _settingsStore.load();
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  Future<void> _setPacing(String value) async {
    final settings = _settings;
    if (settings == null) return;

    settings.applyPacingPreset(value);
    await _settingsStore.save(settings);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _setTransferTraining(bool enabled) async {
    final settings = _settings;
    if (settings == null) return;

    settings.transferTrainingEnabled = enabled;
    await _settingsStore.save(settings);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _exportBackup() async {
    final learning = await _progressStore.load();
    final career = await _careerStore.load();
    final settings = await _settingsStore.load();

    final payload = MorseboundBackupCodec.encode(
      learning: learning.toJson(),
      career: career.toJson(),
      settings: settings.toJson(),
      exportedAt: DateTime.now(),
    );

    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Integrity-checked Morsebound backup copied to clipboard.',
        ),
      ),
    );
  }

  Future<void> _restoreBackup() async {
    final clipboard =
        await Clipboard.getData(Clipboard.kTextPlain);
    final raw = clipboard?.text?.trim();

    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard is empty.'),
        ),
      );
      return;
    }

    late final MorseboundBackupBundle bundle;

    try {
      bundle = MorseboundBackupCodec.decode(raw);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Morsebound backup?'),
            content: Text(
              'This replaces the local learning profile, career statistics, '
              'and settings with the validated clipboard backup.\n\n'
              'Backup date: ${bundle.exportedAt}',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(true),
                child: const Text('RESTORE'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await _progressStore.save(
        LearningSnapshot.fromJson(bundle.learning),
      );
      await _careerStore.save(
        CareerProfile.fromJson(bundle.career),
      );
      await _settingsStore.save(
        AppSettings.fromJson(bundle.settings),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $error'),
        ),
      );
      return;
    }

    if (!mounted) return;

    await _load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Morsebound backup restored successfully.',
        ),
      ),
    );
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset all Morsebound progress?'),
            content: const Text(
              'This permanently clears learning mastery, career stats, '
              'streaks, and preferences on this device/browser.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(true),
                child: const Text('RESET ALL'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await _progressStore.reset();
    await _careerStore.reset();
    await _settingsStore.reset();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Progress reset. Restart Morsebound to see onboarding again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(title: const Text('MORSEBOUND SETTINGS')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'AUDIO PACING',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Character speed stays fast. '
                                'This changes only the spacing between '
                                'characters in word/real-copy practice.',
                              ),
                              const SizedBox(height: 14),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'Comfort',
                                    label: Text('Comfort'),
                                  ),
                                  ButtonSegment(
                                    value: 'Standard',
                                    label: Text('Standard'),
                                  ),
                                  ButtonSegment(
                                    value: 'Fast',
                                    label: Text('Fast'),
                                  ),
                                ],
                                selected: {settings.pacingLabel},
                                onSelectionChanged: (value) =>
                                    _setPacing(value.first),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'REAL-WORLD TRANSFER',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: SwitchListTile(
                          value: settings.transferTrainingEnabled,
                          onChanged: _setTransferTraining,
                          title: const Text(
                            'Adaptive field-signal variation',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text(
                            'Recommended. As mastery grows, Morsebound '
                            'gradually varies pitch, sender timing, and '
                            'radio texture so recognition transfers beyond '
                            'one perfect training tone.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PUBLIC UPDATES',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.public_rounded),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _independentUpdateStatus?.available == true
                                              ? 'Public update available'
                                              : _independentUpdateStatus?.supported == true
                                                  ? 'Public release channel current'
                                                  : 'Android public channel activates in signed release builds',
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Installed: ${ReleaseInfo.displayVersion}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_independentUpdateStatus?.actionable == true)
                                    FilledButton.tonal(
                                      onPressed: _runIndependentUpdate,
                                      child: Text(
                                        _independentUpdateStatus?.action ==
                                                IndependentUpdateAction.refreshWeb
                                            ? 'REFRESH'
                                            : 'UPDATE',
                                      ),
                                    )
                                  else
                                    IconButton(
                                      tooltip: 'Check public release channel',
                                      onPressed: _checkIndependentUpdate,
                                      icon: const Icon(Icons.refresh_rounded),
                                    ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.shop_outlined, size: 20),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Google Play updates remain optional and only activate on Play installs.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  if (_updateStatus?.actionable == true)
                                    TextButton(
                                      onPressed: _startUpdate,
                                      child: const Text('PLAY UPDATE'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'YOUR DATA',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _exportBackup,
                                icon: const Icon(Icons.copy_all),
                                label: const Text(
                                  'COPY BACKUP TO CLIPBOARD',
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _restoreBackup,
                                icon: const Icon(Icons.restore),
                                label: const Text(
                                  'RESTORE BACKUP FROM CLIPBOARD',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _resetAll,
                                icon: const Icon(
                                  Icons.delete_forever_outlined,
                                ),
                                label:
                                    const Text('RESET ALL PROGRESS'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ABOUT',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                ReleaseInfo.appName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version ${ReleaseInfo.displayVersion}',
                              ),
                              const SizedBox(height: 4),
                              const Text(ReleaseInfo.packageId),
                              const SizedBox(height: 12),
                              const Text(
                                'An adaptive sound-first Morse learning game.',
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Privacy: learning progress is stored locally '
                                'on this device/browser. Morsebound does not '
                                'require an account or analytics service.',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                '${ReleaseInfo.brand}\n'
                                '${ReleaseInfo.creatorCredit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
