import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';

import '../screens/desktop_webview_screen.dart';

bool isDesktopPlatform() {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

// Uses defaultTargetPlatform (safe on every platform incl. web) instead of
// dart:io Platform.isAndroid, which throws UnsupportedError on Flutter web.
// This getter is imported unconditionally by glass/card widgets that also
// render in the web/PWA build.
bool get shouldUseBlur =>
    kIsWeb || defaultTargetPlatform != TargetPlatform.android;

Widget buildDesktopHome() {
  return const DesktopWebViewScreen();
}
