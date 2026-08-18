import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/release/independent_update_service.dart';

void main() {
  test('newer independent build is actionable', () {
    const status = IndependentUpdateStatus(
      supported: true,
      available: true,
      currentBuild: 15,
      latestBuild: 16,
      latestVersion: '1.2.1',
      action: IndependentUpdateAction.openDownload,
      actionUrl: 'https://example.com/Morsebound.apk',
    );
    expect(status.actionable, isTrue);
  });

  test('current build has no update action', () {
    const status = IndependentUpdateStatus(
      supported: true,
      available: false,
      currentBuild: 15,
      latestBuild: 15,
      latestVersion: '1.2.0',
      action: IndependentUpdateAction.none,
    );
    expect(status.actionable, isFalse);
  });
}
