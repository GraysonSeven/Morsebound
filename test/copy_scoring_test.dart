import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/training/copy_scoring.dart';

void main() {
  test('normalization ignores case and repeated spaces', () {
    expect(
      CopyScoring.normalize('  hello   world '),
      'HELLO WORLD',
    );
  });

  test('exact copy is 100 percent', () {
    expect(CopyScoring.accuracy('HELLO', 'hello'), 1);
  });

  test('partial copy receives partial credit', () {
    final score = CopyScoring.accuracy('MORSE', 'MORS');
    expect(score, greaterThan(0.7));
    expect(score, lessThan(1));
  });
}
