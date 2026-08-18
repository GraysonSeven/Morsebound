import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('professional About and legal surface source contract', () {
    final account = File('lib/ui/account_screen.dart').readAsStringSync();
    final about =
        File('lib/ui/about_morsebound_screen.dart').readAsStringSync();
    final legal =
        File('lib/ui/legal_information_screen.dart').readAsStringSync();

    expect(account, contains('ABOUT MORSEBOUND'));
    expect(account, contains('PRIVACY'));
    expect(account, contains('TERMS'));
    expect(account, contains('DELETE ACCOUNT'));
    expect(account, contains('LegalSection.privacy'));
    expect(account, contains('LegalSection.terms'));
    expect(account, contains('LegalSection.deletion'));

    expect(about, contains('ABOUT MORSEBOUND'));
    expect(about, contains('TRAINING APPROACH'));
    expect(about, contains('ACCOUNTS & SYNC'));
    expect(about, contains('LEGAL & DATA'));

    expect(legal, contains('MORSEBOUND PRIVACY POLICY'));
    expect(legal, contains('MORSEBOUND TERMS OF USE'));
    expect(legal, contains('ACCOUNT & DATA DELETION'));
    expect(legal, contains('Firebase Authentication'));
    expect(legal, contains('Cloud Firestore'));

    for (final file in [
      'web/privacy.html',
      'web/terms.html',
      'web/delete-account.html',
      'web/about.html',
    ]) {
      expect(File(file).existsSync(), isTrue, reason: '$file must exist');
    }
  });
}
