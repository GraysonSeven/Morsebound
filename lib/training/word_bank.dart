import 'dart:math';

class WordBank {
  const WordBank._();

  static const List<String> words = [
    'AM', 'AS', 'AT', 'ME', 'MY', 'NO', 'ON', 'OR', 'TO', 'UP', 'US',
    'MAP', 'ARM', 'RAM', 'SUM', 'RUM', 'SAT', 'MAT', 'TAP', 'ART',
    'PART', 'START', 'STOP', 'POST', 'SORT', 'PORT', 'TRAP', 'STAR',
    'RATE', 'TEAM', 'TIME', 'MORE', 'SOME', 'HOME', 'COME', 'MOVE',
    'WAVE', 'WIRE', 'WORK', 'WORD', 'READ', 'SEND', 'CODE', 'RADIO',
    'SIGNAL', 'CALL', 'COPY', 'READY', 'YES', 'HELP', 'NORTH', 'SOUTH',
    'EAST', 'WEST', 'LEFT', 'RIGHT', 'FIRE', 'SAFE', 'BASE', 'FAST',
    'SLOW', 'CLEAR', 'POWER', 'LIGHT', 'WATER', 'HOUSE', 'PHONE',
    'HELLO', 'WORLD', 'MORSE', 'TRAIN', 'LEARN', 'SKILL', 'SOUND',
  ];

  static List<String> eligible(Set<String> unlocked) {
    final result = <String>[];
    for (final word in words) {
      if (word.split('').every(unlocked.contains)) {
        result.add(word);
      }
    }
    return result;
  }

  static List<String> choices({
    required String target,
    required List<String> pool,
    required Random random,
    int maxChoices = 4,
  }) {
    final wanted = min(maxChoices, pool.length);
    final values = <String>{target};
    final shuffled = List<String>.from(pool)..shuffle(random);

    for (final word in shuffled) {
      values.add(word);
      if (values.length >= wanted) break;
    }

    final result = values.toList()..shuffle(random);
    return result;
  }
}
