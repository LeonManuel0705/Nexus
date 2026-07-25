import 'package:flutter/widgets.dart';

bool isDesktopPlatform() => false;

// Web always supports backdrop blur; keep the symbol in parity with the
// native platform_utils.dart so either import resolves it.
bool get shouldUseBlur => true;

Widget buildDesktopHome() {
  throw UnsupportedError('Desktop home not available on web');
}
