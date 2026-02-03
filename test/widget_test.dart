import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MithaqApp()));

    // Verify that our app starts. Since we removed the counter,
    // we should just verify it doesn't crash and maybe some text exists.
    expect(find.byType(MithaqApp), findsOneWidget);
  });
}
