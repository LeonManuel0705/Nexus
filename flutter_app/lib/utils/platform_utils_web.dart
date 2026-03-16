import 'package:flutter/widgets.dart';

bool isDesktopPlatform() => false;

Widget buildDesktopHome() {
  throw UnsupportedError('Desktop home not available on web');
}
