import 'package:flutter/services.dart';

const _channel = MethodChannel('com.icharles.morsebound/app_update');

Future<bool> openUpdateUrl(String url) async {
  try {
    return await _channel.invokeMethod<bool>('openExternalUrl', {'url': url}) ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

Future<bool> refreshWebApp() async => false;
