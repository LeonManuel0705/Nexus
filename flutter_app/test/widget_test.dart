import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexus/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NexusApp());
    await tester.pumpAndSettle();

    expect(find.text('Nexus'), findsWidgets);
  });
}
