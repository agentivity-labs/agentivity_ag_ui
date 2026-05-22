import 'package:flutter_test/flutter_test.dart';

import 'package:example_agentivity/main.dart';

void main() {
  testWidgets('AgentivityClientApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AgentivityClientApp());
    await tester.pumpAndSettle();
    // App rendered without exception
  });
}
