import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'release_info.dart';
import 'update_navigation.dart';

enum IndependentUpdateAction { none, refreshWeb, openDownload, openSamsungStore }

class IndependentUpdateStatus {
  const IndependentUpdateStatus({
    required this.supported,
    required this.available,
    required this.currentBuild,
    required this.latestBuild,
    required this.latestVersion,
    required this.action,
    this.message = '',
    this.actionUrl = '',
    this.mandatory = false,
    this.error,
  });

  final bool supported;
  final bool available;
  final int currentBuild;
  final int latestBuild;
  final String latestVersion;
  final IndependentUpdateAction action;
  final String message;
  final String actionUrl;
  final bool mandatory;
  final String? error;

  bool get actionable =>
      supported && available && action != IndependentUpdateAction.none;

  factory IndependentUpdateStatus.notConfigured() =>
      const IndependentUpdateStatus(
        supported: false,
        available: false,
        currentBuild: ReleaseInfo.build,
        latestBuild: ReleaseInfo.build,
        latestVersion: ReleaseInfo.version,
        action: IndependentUpdateAction.none,
      );
}

class IndependentUpdateService {
  const IndependentUpdateService();

  Future<IndependentUpdateStatus> check() async {
    final uri = _manifestUri();
    if (uri == null) return IndependentUpdateStatus.notConfigured();

    try {
      final base = uri.resolve('.');
      final file = uri.pathSegments.isEmpty ? 'release.json' : uri.pathSegments.last;
      final raw = await NetworkAssetBundle(base)
          .loadString(file)
          .timeout(const Duration(seconds: 8));
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);

      if ((data['schema'] as num?)?.toInt() != 1) {
        throw const FormatException('Unsupported release manifest.');
      }

      final latestBuild = (data['build'] as num?)?.toInt() ?? ReleaseInfo.build;
      final latestVersion = data['version'] as String? ?? ReleaseInfo.version;
      final minSupported = (data['minSupportedBuild'] as num?)?.toInt() ?? 0;
      final available = latestBuild > ReleaseInfo.build;
      final mandatory = available && ReleaseInfo.build < minSupported;
      final message = data['message'] as String? ?? '';

      if (kIsWeb) {
        return IndependentUpdateStatus(
          supported: true,
          available: available,
          currentBuild: ReleaseInfo.build,
          latestBuild: latestBuild,
          latestVersion: latestVersion,
          action: available
              ? IndependentUpdateAction.refreshWeb
              : IndependentUpdateAction.none,
          message: message,
          mandatory: mandatory,
        );
      }

      if (defaultTargetPlatform != TargetPlatform.android) {
        return IndependentUpdateStatus.notConfigured();
      }

      final android = data['android'] is Map
          ? Map<String, dynamic>.from(data['android'] as Map)
          : const <String, dynamic>{};
      final downloadUrl = (android['downloadUrl'] as String? ?? '').trim();
      final samsungUrl = (android['samsungStoreUrl'] as String? ?? '').trim();

      final action = downloadUrl.isNotEmpty
          ? IndependentUpdateAction.openDownload
          : samsungUrl.isNotEmpty
              ? IndependentUpdateAction.openSamsungStore
              : IndependentUpdateAction.none;
      final actionUrl = downloadUrl.isNotEmpty ? downloadUrl : samsungUrl;

      return IndependentUpdateStatus(
        supported: true,
        available: available,
        currentBuild: ReleaseInfo.build,
        latestBuild: latestBuild,
        latestVersion: latestVersion,
        action: available ? action : IndependentUpdateAction.none,
        actionUrl: actionUrl,
        message: message,
        mandatory: mandatory,
      );
    } catch (error) {
      return IndependentUpdateStatus(
        supported: true,
        available: false,
        currentBuild: ReleaseInfo.build,
        latestBuild: ReleaseInfo.build,
        latestVersion: ReleaseInfo.version,
        action: IndependentUpdateAction.none,
        error: error.toString(),
      );
    }
  }

  Future<bool> perform(IndependentUpdateStatus status) async {
    if (!status.actionable) return false;
    switch (status.action) {
      case IndependentUpdateAction.refreshWeb:
        return refreshWebApp();
      case IndependentUpdateAction.openDownload:
      case IndependentUpdateAction.openSamsungStore:
        if (status.actionUrl.isEmpty) return false;
        return openUpdateUrl(status.actionUrl);
      case IndependentUpdateAction.none:
        return false;
    }
  }

  Uri? _manifestUri() {
    final configured = ReleaseInfo.independentUpdateManifestUrl.trim();
    if (configured.isNotEmpty) return Uri.tryParse(configured);
    if (kIsWeb) return Uri.base.resolve('release.json');
    return null;
  }
}
