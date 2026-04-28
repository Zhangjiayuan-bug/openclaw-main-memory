import 'package:flutter_test/flutter_test.dart';
import 'package:workflow_app/main.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const WorkflowApp());
  });
}
