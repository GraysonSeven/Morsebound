import 'package:flutter/material.dart';

import '../cloud/cloud_account_service.dart';
import 'about_morsebound_screen.dart';
import 'legal_information_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    this.launchMode = false,
    this.onContinueOffline,
  });

  final bool launchMode;
  final VoidCallback? onContinueOffline;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _cloud = CloudAccountService.instance;
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _createMode = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.launchMode,
          title: Text(
            widget.launchMode ? 'WELCOME TO MORSEBOUND' : 'MORSEBOUND ACCOUNT',
          ),
        ),
        body: ValueListenableBuilder<CloudAccountState>(
          valueListenable: _cloud.state,
          builder: (context, state, _) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: state.available
                    ? (state.signedIn
                        ? _signedIn(state)
                        : _signedOut(state))
                    : _notConfigured(state),
              ),
            ),
          ),
        ),
      );

  Widget _notConfigured(CloudAccountState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 54,
                    color: Color(0xFFFFD166),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'CLOUD ACCOUNT TEMPORARILY UNAVAILABLE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Morsebound can still run locally. You can continue '
                    'without an account for this session and sign in later.',
                    textAlign: TextAlign.center,
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFB4AB),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _offlineChoice(),
        ],
      );

  Widget _signedOut(CloudAccountState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.launchMode) ...[
            const Text(
              'SIGN IN BEFORE TRAINING',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Keep your Morse mastery, retention schedule, career progress, '
              'streaks, and settings backed up and synchronized across Web '
              'and Android.',
              style: TextStyle(
                color: Color(0xFFA9BBC1),
                height: 1.4,
              ),
            ),
          ] else ...[
            const Text(
              'YOUR MORSEBOUND ACCOUNT',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to keep mastery, retention, career progress, streaks, '
              'and settings synchronized across devices.',
              style: TextStyle(color: Color(0xFFA9BBC1)),
            ),
          ],
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _hidePassword,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _hidePassword = !_hidePassword,
                        ),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: const TextStyle(color: Color(0xFFFFB4AB)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _createMode
                                ? Icons.person_add_alt_1_rounded
                                : Icons.login_rounded,
                          ),
                    label: Text(
                      _createMode ? 'CREATE ACCOUNT' : 'SIGN IN',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Color(0xFF82969D),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _signInWithGoogle,
                    icon: const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 28,
                    ),
                    label: const Text('CONTINUE WITH GOOGLE'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(
                              () => _createMode = !_createMode,
                            ),
                    child: Text(
                      _createMode
                          ? 'I ALREADY HAVE AN ACCOUNT'
                          : 'CREATE A NEW ACCOUNT',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _resetPassword,
                    child: const Text('FORGOT PASSWORD?'),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'By signing in or creating an account, you agree to the '
                    'Morsebound Terms of Use and acknowledge the Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF82969D),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _openLegal(LegalSection.privacy),
                        child: const Text('PRIVACY'),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _openLegal(LegalSection.terms),
                        child: const Text('TERMS'),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _openLegal(LegalSection.deletion),
                        child: const Text('DELETE ACCOUNT'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _openAbout,
                    icon: const Icon(Icons.info_outline_rounded),
                    label: const Text('ABOUT MORSEBOUND'),
                  ),
                ],
              ),
            ),
          ),
          _offlineChoice(),
          const SizedBox(height: 12),
          const Text(
            'Offline-first: local training still works without an account. '
            'Signing in is recommended so progress can be recovered on '
            'another device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF82969D),
              fontSize: 12,
            ),
          ),
        ],
      );

  Widget _offlineChoice() {
    if (!widget.launchMode || widget.onContinueOffline == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextButton.icon(
        onPressed: _busy ? null : widget.onContinueOffline,
        icon: const Icon(Icons.offline_bolt_outlined),
        label: const Text('CONTINUE WITHOUT ACCOUNT'),
      ),
    );
  }

  Widget _signedIn(CloudAccountState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_done_rounded,
                    size: 58,
                    color: Color(0xFF8FFFEA),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CLOUD SYNC ACTIVE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(state.user?.email ?? 'Morsebound user'),
                  const SizedBox(height: 8),
                  Text(
                    state.syncing
                        ? 'Synchronizing progress...'
                        : state.lastSync == null
                            ? 'Ready to synchronize'
                            : 'Last sync: ${_formatSync(state.lastSync!)}',
                    style: const TextStyle(
                      color: Color(0xFFA9BBC1),
                      fontSize: 12,
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFFB4AB)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: state.syncing ? null : () => _cloud.syncNow(),
            icon: const Icon(Icons.sync_rounded),
            label: const Text('SYNC NOW'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('SIGN OUT'),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _busy ? null : _openAbout,
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text('ABOUT MORSEBOUND & LEGAL'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _busy ? null : _deleteAccount,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('DELETE CLOUD ACCOUNT'),
          ),
        ],
      );

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      _show('Enter both email and password.');
      return;
    }

    setState(() => _busy = true);
    try {
      if (_createMode) {
        await _cloud.createAccount(
          email: email,
          password: password,
        );
      } else {
        await _cloud.signIn(
          email: email,
          password: password,
        );
      }
    } catch (_) {
      // Friendly auth errors are exposed by CloudAccountState.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      await _cloud.signInWithGoogle();
    } catch (_) {
      // Friendly auth errors are exposed by CloudAccountState.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _show('Enter your email first.');
      return;
    }

    setState(() => _busy = true);
    try {
      await _cloud.sendPasswordReset(email);
      _show('Password reset email sent.');
    } catch (_) {
      // Friendly auth errors are exposed by CloudAccountState.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await _cloud.signOut();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete cloud account?'),
            content: const Text(
              'This deletes the online Morsebound progress and the cloud '
              'account. Local progress on this device is kept unless you '
              'separately reset it.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('DELETE'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() => _busy = true);
    try {
      await _cloud.deleteCloudAccount();
    } catch (_) {
      // Friendly auth errors are exposed by CloudAccountState.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AboutMorseboundScreen(),
      ),
    );
  }

  void _openLegal(LegalSection section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalInformationScreen(initialSection: section),
      ),
    );
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatSync(DateTime time) {
    final local = time.toLocal();
    return '${local.month}/${local.day} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
