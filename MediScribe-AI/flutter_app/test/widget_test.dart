import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediscribe_app/widgets/custom_button.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('renders label correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Test Button',
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('triggers onPressed callback when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Click Me',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Click Me'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('does not trigger onPressed when disabled (null)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      // Verify widget renders
      expect(find.text('Disabled'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('renders loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Loading',
              isLoading: true,
            ),
          ),
        ),
      );

      // Verify the CircularProgressIndicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders icon when icon parameter is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'With Icon',
              icon: Icons.add,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
