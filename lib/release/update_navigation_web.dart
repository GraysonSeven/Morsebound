import 'dart:js_interop';

@JS('morseboundOpenExternal')
external void _openExternal(JSString url);

@JS('morseboundRefresh')
external void _refresh();

Future<bool> openUpdateUrl(String url) async {
  _openExternal(url.toJS);
  return true;
}

Future<bool> refreshWebApp() async {
  _refresh();
  return true;
}
