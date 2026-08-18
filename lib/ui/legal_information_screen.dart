import 'package:flutter/material.dart';

enum LegalSection { privacy, terms, deletion }

class LegalInformationScreen extends StatelessWidget {
  const LegalInformationScreen({
    super.key,
    required this.initialSection,
  });

  final LegalSection initialSection;

  @override
  Widget build(BuildContext context) {
    final data = switch (initialSection) {
      LegalSection.privacy => _privacy,
      LegalSection.terms => _terms,
      LegalSection.deletion => _deletion,
    };

    return Scaffold(
      appBar: AppBar(title: Text(data.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.effective,
                    style: const TextStyle(
                      color: Color(0xFF82969D),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final item in data.sections) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: const TextStyle(
                                color: Color(0xFF8FFFEA),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: Color(0xFFC2D0D4),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Public copies:',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'https://graysonseven.github.io/Morsebound/privacy.html\n'
                    'https://graysonseven.github.io/Morsebound/terms.html\n'
                    'https://graysonseven.github.io/Morsebound/delete-account.html',
                    style: TextStyle(
                      color: Color(0xFF8FFFEA),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _privacy = _LegalData(
    title: 'MORSEBOUND PRIVACY POLICY',
    effective: 'Effective August 19, 2026',
    sections: [
      (
        'Local learning data',
        'Morsebound stores learning progress and preferences locally on the '
            'device or browser. This can include mastery and retention state, '
            'accuracy and reaction-time statistics, confusion history, '
            'streaks, progression information, and app settings.'
      ),
      (
        'Accounts and authentication',
        'Morsebound offers email/password and Google Sign-In through Firebase '
            'Authentication. Authentication can process account identifiers '
            'such as email address, Firebase user ID, and authentication '
            'provider information needed to operate the account.'
      ),
      (
        'Cloud synchronization',
        'When signed in, Morsebound can store synchronized learning state in '
            'Cloud Firestore under the authenticated user ID. This can include '
            'mastery/retention progress, career and streak information, and '
            'app settings. Per-user Firestore rules restrict app access to '
            'the authenticated user’s own Morsebound data.'
      ),
      (
        'Advertising and analytics',
        'Morsebound does not include advertising or a dedicated analytics '
            'service in this release and does not sell personal information.'
      ),
      (
        'Permissions',
        'Current learning modes do not require microphone recording, camera '
            'access, phone contacts, or precise location.'
      ),
      (
        'Retention and deletion',
        'Local data remains until reset, app/browser storage is cleared, or '
            'the app is removed as applicable. Cloud account data can be '
            'deleted through Delete Cloud Account. A public deletion resource '
            'is also available for users who cannot access the app.'
      ),
      (
        'Contact',
        'Privacy and account-deletion requests may be sent to '
            'cselrahc.117@gmail.com. Never send passwords, authentication '
            'codes, or other secret credentials.'
      ),
    ],
  );

  static const _terms = _LegalData(
    title: 'MORSEBOUND TERMS OF USE',
    effective: 'Effective August 19, 2026',
    sections: [
      (
        'Educational purpose',
        'Morsebound is an educational Morse code practice tool. It is not an '
            'emergency communications service, professional certification, '
            'or guarantee of a particular learning outcome.'
      ),
      (
        'Accounts',
        'Users are responsible for protecting their sign-in credentials and '
            'must not attempt to access another user’s account or cloud data. '
            'Local/offline use remains available where the app provides it.'
      ),
      (
        'Acceptable use',
        'Use Morsebound lawfully. Do not interfere with its infrastructure, '
            'bypass access controls, abuse authentication systems, distribute '
            'malware, or intentionally damage the service.'
      ),
      (
        'Availability',
        'Features, platforms, and third-party services can change. Morsebound '
            'may be improved, updated, suspended, or discontinued.'
      ),
      (
        'No warranty',
        'To the extent permitted by applicable law, Morsebound is provided '
            'as-is and as-available without a guarantee that it will be '
            'uninterrupted, error-free, or suitable for every purpose.'
      ),
      (
        'Contact',
        'Questions about these terms may be sent to '
            'cselrahc.117@gmail.com.'
      ),
    ],
  );

  static const _deletion = _LegalData(
    title: 'ACCOUNT & DATA DELETION',
    effective: 'Last updated August 19, 2026',
    sections: [
      (
        'Delete inside Morsebound',
        'Sign in, open Settings, open Account & cloud sync, choose Delete '
            'Cloud Account, and confirm. The current deletion flow removes '
            'the synchronized Morsebound Firestore state associated with the '
            'account and then deletes the Firebase Authentication account.'
      ),
      (
        'Delete without the app',
        'If the app is unavailable, send a Morsebound Account Deletion '
            'Request to cselrahc.117@gmail.com and identify the email address '
            'used for the Morsebound account. Additional verification may be '
            'required for account security.'
      ),
      (
        'What is deleted',
        'The Morsebound Firebase Authentication account and synchronized '
            'Morsebound cloud learning state associated with that user.'
      ),
      (
        'Local data',
        'Deleting a cloud account does not automatically erase local/offline '
            'progress stored on a device or browser. Use local reset controls, '
            'clear app/browser storage, or uninstall the app as appropriate.'
      ),
      (
        'Security reminder',
        'Never send your password, Google password, one-time code, recovery '
            'code, or other secret credential in a deletion request.'
      ),
    ],
  );
}

class _LegalData {
  const _LegalData({
    required this.title,
    required this.effective,
    required this.sections,
  });

  final String title;
  final String effective;
  final List<(String, String)> sections;
}
