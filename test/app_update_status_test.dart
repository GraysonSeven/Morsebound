import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/release/app_update_service.dart';

void main() {
  test('Play update status parses native bridge data', () {
    final status = AppUpdateStatus.fromMap({
      'supported': true,
      'available': true,
      'downloaded': false,
      'flexibleAllowed': true,
      'immediateAllowed': true,
      'priority': 3,
      'stalenessDays': 2,
    });

    expect(status.supported, isTrue);
    expect(status.available, isTrue);
    expect(status.flexibleAllowed, isTrue);
    expect(status.priority, 3);
    expect(status.stalenessDays, 2);
    expect(status.actionable, isTrue);
  });

  test('downloaded update is actionable', () {
    final status = AppUpdateStatus.fromMap({
      'supported': true,
      'available': false,
      'downloaded': true,
      'flexibleAllowed': true,
      'immediateAllowed': false,
    });

    expect(status.downloaded, isTrue);
    expect(status.actionable, isTrue);
  });

  test('unsupported platform is not actionable', () {
    expect(AppUpdateStatus.unsupported().actionable, isFalse);
  });
}
