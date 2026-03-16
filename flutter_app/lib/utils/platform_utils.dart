import 'dart:io' show Platform;

import '../screens/desktop_webview_screen.dart';
import 'package:flutter/widgets.dart';

bool isDesktopPlatform() {
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

/// BackdropFilter blur is extremely expensive on mobile GPUs.
/// Disable it on Android to avoid lag.
bool get shouldUseBlur => !Platform.isAndroid;

Widget buildDesktopHome() {
  return const DesktopWebViewScreen();
}
