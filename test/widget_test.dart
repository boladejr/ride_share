import 'package:flutter_test/flutter_test.dart';

import 'package:ride_share/main.dart';

void main() {
  testWidgets('App renders landing page', (WidgetTester tester) async {
    await tester.pumpWidget(const RideShareApp());
    expect(find.text('RideShare'), findsOneWidget);
  });
}
