import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/training/word_bank.dart';

void main() {
  test('eligible words contain only unlocked characters', () {
    final unlocked = {'M', 'A', 'P', 'R', 'T', 'S', 'U'};
    final words = WordBank.eligible(unlocked);

    expect(words, contains('MAP'));
    expect(words, contains('RAM'));
    expect(words, isNot(contains('CODE')));

    for (final word in words) {
      expect(word.split('').every(unlocked.contains), isTrue);
    }
  });

  test('word choices always include target without duplicates', () {
    final pool = ['MAP', 'RAM', 'SUM', 'MAT'];
    final choices = WordBank.choices(
      target: 'MAP',
      pool: pool,
      random: Random(1),
    );

    expect(choices, contains('MAP'));
    expect(choices.toSet().length, choices.length);
  });
}
