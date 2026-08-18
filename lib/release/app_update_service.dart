import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppUpdateStatus {
  const AppUpdateStatus({
    required this.supported,
    required this.available,
    required this.downloaded,
    required this.flexibleAllowed,
    required this.immediateAllowed,
    this.priority,
    this.stalenessDays,
    this.error,
  });

  final bool supported;
  final bool available;
  final bool downloaded;
  final bool flexibleAllowed;
  final bool immediateAllowed;
  final int? priority;
  final int? stalenessDays;
  final String? error;

  bool get actionable => supported && (available || downloaded);

  factory AppUpdateStatus.unsupported() => const AppUpdateStatus(
        supported: false,
        available: false,
        downloaded: false,
        flexibleAllowed: false,
        immediateAllowed: false,
      );

  factory AppUpdateStatus.fromMap(Map<dynamic, dynamic> map) =>
      AppUpdateStatus(
        supported: map['supported'] == true,
        available: map['available'] == true,
        downloaded: map['downloaded'] == true,
        flexibleAllowed: map['flexibleAllowed'] == true,
        immediateAllowed: map['immediateAllowed'] == true,
        priority: (map['priority'] as num?)?.toInt(),
        stalenessDays: (map['stalenessDays'] as num?)?.toInt(),
      );

  AppUpdateStatus copyWith({String? error}) => AppUpdateStatus(
        supported: supported,
        available: available,
        downloaded: downloaded,
        flexibleAllowed: flexibleAllowed,
        immediateAllowed: immediateAllowed,
        priority: priority,
        stalenessDays: stalenessDays,
        error: error,
      );
}

class AppUpdateService {
  AppUpdateService._() {
    _channel.setMethodCallHandler(_handleNativeEvent);
  }

  static final AppUpdateService instance = AppUpdateService._();

  static const MethodChannel _channel =
      MethodChannel('com.icharles.morsebound/app_update');

  final StreamController<AppUpdateStatus> _changes =
      StreamController<AppUpdateStatus>.broadcast();

  Stream<AppUpdateStatus> get changes => _changes.stream;

  bool get _isAndroidPlayCandidate =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<AppUpdateStatus> check() async {
    if (!_isAndroidPlayCandidate) {
      return AppUpdateStatus.unsupported();
    }

    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'checkForUpdate',
      );

      if (map == null) {
        return AppUpdateStatus.unsupported();
      }

      return AppUpdateStatus.fromMap(map);
    } on MissingPluginException {
      return AppUpdateStatus.unsupported();
    } on PlatformException catch (error) {
      return AppUpdateStatus(
        supported: true,
        available: false,
        downloaded: false,
        flexibleAllowed: false,
        immediateAllowed: false,
        error: error.message ?? error.code,
      );
    }
  }

  Future<bool> startFlexibleUpdate() async {
    if (!_isAndroidPlayCandidate) return false;

    try {
      return await _channel.invokeMethod<bool>(
            'startFlexibleUpdate',
          ) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> completeUpdate() async {
    if (!_isAndroidPlayCandidate) return false;

    try {
      return await _channel.invokeMethod<bool>('completeUpdate') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _handleNativeEvent(MethodCall call) async {
    if (call.method != 'updateDownloaded') return;

    final status = await check();
    _changes.add(status);
  }
}
