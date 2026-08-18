import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/game/signal_ops_mission.dart';

void main() {
  test('Signal Ops phases advance across a mission', () {
    expect(
      SignalOpsMission.phaseFor(completed: 0, total: 24),
      'ACQUIRE',
    );
    expect(
      SignalOpsMission.phaseFor(completed: 6, total: 24),
      'STABILIZE',
    );
    expect(
      SignalOpsMission.phaseFor(completed: 12, total: 24),
      'ROUTE',
    );
    expect(
      SignalOpsMission.phaseFor(completed: 18, total: 24),
      'SECURE',
    );
  });

  test('relay goals scale with mission length', () {
    expect(SignalOpsMission.relayGoalFor(24), 8);
    expect(SignalOpsMission.relayGoalFor(12), 4);
  });
}
