import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltron_app/main.dart';

void main() {
  testWidgets('Splash screen shows the Voltron logo', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VoltronApp()));

    expect(find.text('VOLTRON'), findsOneWidget);
  });
}
