import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/storage/backup_codec.dart';

void main() {
  test('backup round trip preserves all three data domains', () {
    final encoded = MorseboundBackupCodec.encode(
      learning: {'unlockedCount': 12},
      career: {'missionsCompleted': 9},
      settings: {'transferTrainingEnabled': true},
      exportedAt: DateTime.utc(2026, 8, 18, 12),
    );

    final decoded = MorseboundBackupCodec.decode(encoded);

    expect(decoded.learning['unlockedCount'], 12);
    expect(decoded.career['missionsCompleted'], 9);
    expect(decoded.settings['transferTrainingEnabled'], true);
  });

  test('backup integrity check rejects a changed payload', () {
    final encoded = MorseboundBackupCodec.encode(
      learning: {'unlockedCount': 12},
      career: {},
      settings: {},
      exportedAt: DateTime.utc(2026, 8, 18, 12),
    );

    final envelope =
        Map<String, dynamic>.from(jsonDecode(encoded) as Map);

    envelope['payload'] =
        (envelope['payload'] as String).replaceFirst('12', '13');

    expect(
      () => MorseboundBackupCodec.decode(jsonEncode(envelope)),
      throwsA(isA<MorseboundBackupException>()),
    );
  });

  test('random clipboard text is rejected', () {
    expect(
      () => MorseboundBackupCodec.decode('not a backup'),
      throwsA(isA<MorseboundBackupException>()),
    );
  });
}
