class ReleaseInfo {
  const ReleaseInfo._();

  static const appName = 'Morsebound';
  static const version = '1.2.0';
  static const build = 15;
  static const packageId = 'com.icharles.morsebound';

  static const brand = 'iCharles';
  static const creatorCredit =
      'by iCharles — Charles Leanne S. Lioc';

  /// Product-learning contract: main recognition gameplay stays auditory.
  static const soundFirstMainGame = true;

  static const independentUpdateManifestUrl = String.fromEnvironment(
    'MORSEBOUND_UPDATE_MANIFEST_URL',
    defaultValue: '',
  );

  static String get displayVersion => '$version+$build';
}
