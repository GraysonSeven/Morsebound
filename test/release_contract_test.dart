import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/release/release_info.dart';

void main() {
  test('V1 release identity is locked', () {
    expect(ReleaseInfo.appName, 'Morsebound');
    expect(ReleaseInfo.version, '1.4.0');
    expect(ReleaseInfo.build, 21);
    expect(
      ReleaseInfo.packageId,
      'com.icharles.morsebound',
    );
    expect(ReleaseInfo.brand, 'iCharles');
  });

  test('main game remains sound-first by contract', () {
    expect(ReleaseInfo.soundFirstMainGame, isTrue);
  });
}



