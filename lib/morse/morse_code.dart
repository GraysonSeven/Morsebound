class MorseCode {
  static const Map<String, String> patterns = {
    'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.',
    'F': '..-.', 'G': '--.', 'H': '....', 'I': '..', 'J': '.---',
    'K': '-.-', 'L': '.-..', 'M': '--', 'N': '-.', 'O': '---',
    'P': '.--.', 'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-',
    'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-', 'Y': '-.--',
    'Z': '--..',
    '0': '-----', '1': '.----', '2': '..---', '3': '...--', '4': '....-',
    '5': '.....', '6': '-....', '7': '--...', '8': '---..', '9': '----.',
  };

  // Balanced sound-first progression. The first pair follows Koch training.
  static const List<String> learningOrder = [
    'K', 'M', 'R', 'S', 'U', 'A', 'P', 'T', 'L', 'O', 'W', 'I',
    'N', 'J', 'E', 'F', 'Y', 'V', 'G', '5', 'Q', '9', 'Z', 'H',
    '3', '8', 'B', '4', '2', '7', 'C', '1', 'D', '6', 'X', '0',
  ];

  static String patternFor(String character) {
    final value = patterns[character.toUpperCase()];
    if (value == null) {
      throw ArgumentError('Unsupported Morse character: $character');
    }
    return value;
  }

  static String assetNameFor(String character) {
    final c = character.toLowerCase();
    return 'audio/morse/$c.wav';
  }
}


