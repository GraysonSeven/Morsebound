import 'dart:convert';

class MorseboundBackupException implements Exception {
  const MorseboundBackupException(this.message);

  final String message;

  @override
  String toString() => 'MorseboundBackupException: $message';
}

class MorseboundBackupBundle {
  const MorseboundBackupBundle({
    required this.learning,
    required this.career,
    required this.settings,
    required this.exportedAt,
  });

  final Map<String, dynamic> learning;
  final Map<String, dynamic> career;
  final Map<String, dynamic> settings;
  final String exportedAt;
}

class MorseboundBackupCodec {
  const MorseboundBackupCodec._();

  static const format = 'MorseboundBackupV2';

  static String encode({
    required Map<String, dynamic> learning,
    required Map<String, dynamic> career,
    required Map<String, dynamic> settings,
    required DateTime exportedAt,
  }) {
    final payload = jsonEncode({
      'learning': learning,
      'career': career,
      'settings': settings,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
    });

    return jsonEncode({
      'format': format,
      'version': 2,
      'checksum': _checksum(payload),
      'payload': payload,
    });
  }

  static MorseboundBackupBundle decode(String encoded) {
    try {
      final envelope = Map<String, dynamic>.from(
        jsonDecode(encoded) as Map,
      );

      if (envelope['format'] != format || envelope['version'] != 2) {
        throw const MorseboundBackupException(
          'Unsupported Morsebound backup format.',
        );
      }

      final payload = envelope['payload'];
      final checksum = envelope['checksum'];

      if (payload is! String || checksum is! String) {
        throw const MorseboundBackupException(
          'Backup envelope is incomplete.',
        );
      }

      if (_checksum(payload) != checksum) {
        throw const MorseboundBackupException(
          'Backup integrity check failed.',
        );
      }

      final data = Map<String, dynamic>.from(
        jsonDecode(payload) as Map,
      );

      return MorseboundBackupBundle(
        learning: Map<String, dynamic>.from(data['learning'] as Map),
        career: Map<String, dynamic>.from(data['career'] as Map),
        settings: Map<String, dynamic>.from(data['settings'] as Map),
        exportedAt: data['exportedAt'] as String? ?? '',
      );
    } on MorseboundBackupException {
      rethrow;
    } catch (_) {
      throw const MorseboundBackupException(
        'Clipboard does not contain a valid Morsebound backup.',
      );
    }
  }

  static String _checksum(String input) {
    // FNV-1a 32-bit. This is for accidental corruption detection, not
    // authentication or encryption.
    var hash = 0x811C9DC5;

    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }
}
