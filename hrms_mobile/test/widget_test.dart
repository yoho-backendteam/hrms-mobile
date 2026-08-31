import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobile/app/app.dart';

void main() {
  testWidgets('HRMS App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HrmsApp(),
      ),
    );
    expect(find.byType(HrmsApp), findsOneWidget);
  });
}
