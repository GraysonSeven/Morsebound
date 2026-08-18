import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login-first source contract is preserved', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final accountSource =
        File('lib/ui/account_screen.dart').readAsStringSync();

    expect(
      mainSource,
      contains('home: const _LaunchGate()'),
      reason: 'Morsebound must launch through the login-first gate.',
    );
    expect(
      mainSource,
      contains('if (state.signedIn || _continueOfflineForSession)'),
      reason:
          'Signed-in users and explicit offline guests must be allowed into '
          'the main app.',
    );
    expect(
      accountSource,
      contains('SIGN IN BEFORE TRAINING'),
      reason: 'Signed-out launch must clearly request authentication first.',
    );
    expect(
      accountSource,
      contains('CONTINUE WITH GOOGLE'),
      reason: 'Google Sign-In must remain available.',
    );
    expect(
      accountSource,
      contains('CREATE A NEW ACCOUNT'),
      reason: 'Email/password account creation must remain available.',
    );
    expect(
      accountSource,
      contains('CONTINUE WITHOUT ACCOUNT'),
      reason:
          'Local/offline use must remain available only as an explicit choice.',
    );
  });
}
