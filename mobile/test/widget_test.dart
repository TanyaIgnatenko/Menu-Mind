import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App boots into the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MenuMindApp());
    await tester.pump();

    // The splash shows the wordmark and tagline.
    expect(find.text('MenuMind'), findsOneWidget);
    expect(find.text('Read any menu. Anywhere.'), findsOneWidget);
  });
}
