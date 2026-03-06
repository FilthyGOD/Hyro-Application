import 'package:flutter_test/flutter_test.dart';
import 'package:hyro_app/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const HyroApp());
    expect(find.text('Hyro'), findsWidgets);
  });
}
