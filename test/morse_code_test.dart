import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/morse/morse_code.dart';

void main() {
  test('core Morse mappings are correct', () {
    expect(MorseCode.patternFor('A'), '.-');
    expect(MorseCode.patternFor('K'), '-.-');
    expect(MorseCode.patternFor('M'), '--');
    expect(MorseCode.patternFor('S'), '...');
    expect(MorseCode.patternFor('O'), '---');
    expect(MorseCode.patternFor('5'), '.....');
    expect(MorseCode.patternFor('0'), '-----');
  });

  test('learning order covers all supported letters and digits once', () {
    expect(MorseCode.learningOrder.toSet().length, MorseCode.learningOrder.length);
    expect(MorseCode.learningOrder.length, 36);
    expect(MorseCode.learningOrder.first, 'K');
    expect(MorseCode.learningOrder[1], 'M');
  });
}


