import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexus/main.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const NexusApp());
    await tester.pump();

    // The app builds its root tree; that is all this smoke test asserts.
    expect(tester.takeException(), isNull);

    // Tear the app down so State.dispose() cancels controllers/timers, then let
    // any one-shot delayed timers fire (they no-op once unmounted). This keeps
    // the perpetual background animation / update-check timers from tripping the
    // test binding's pending-timer check.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  });
}
