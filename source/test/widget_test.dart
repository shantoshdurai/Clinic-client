import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_app/main.dart';

void main() {
  testWidgets('Clinic app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ClinicApp());
    expect(find.textContaining('AS Clinic'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}
