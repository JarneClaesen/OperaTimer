import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:orchestra_timer/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add opera flow test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Handle notification permission
    final allowNotificationButton = find.text('Allow notifications');
    if (allowNotificationButton.evaluate().isNotEmpty) {
      await tester.tap(allowNotificationButton);
      await tester.pumpAndSettle();
    }

    // Handle battery optimization
    final allowBatteryOptimizationButton = find.text('Allow battery optimization');
    if (allowBatteryOptimizationButton.evaluate().isNotEmpty) {
      await tester.tap(allowBatteryOptimizationButton);
      await tester.pumpAndSettle();
    }

    // Try to find an "Add Opera" button or similar
    final addOperaButton = find.text('Add Opera');
    if (addOperaButton.evaluate().isNotEmpty) {
      await tester.tap(addOperaButton);
    } else {
      // If "Add Opera" button is not found, try to find a FloatingActionButton
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
      } else {
        // If neither is found, fail the test
        fail('Could not find a way to add a new opera');
      }
    }
    await tester.pumpAndSettle();

    // Enter opera name
    final operaNameField = find.widgetWithText(TextFormField, 'Opera Name');
    if (operaNameField.evaluate().isNotEmpty) {
      await tester.enterText(operaNameField, 'Test');
    } else {
      fail('Could not find Opera Name field');
    }

    // Add a part
    final addPartButton = find.widgetWithText(ElevatedButton, 'Add Part');
    if (addPartButton.evaluate().isNotEmpty) {
      await tester.tap(addPartButton);
      await tester.pumpAndSettle();
    } else {
      fail('Could not find Add Part button');
    }

    // Enter part name
    final partNameField = find.widgetWithText(TextFormField, 'Part Name');
    if (partNameField.evaluate().isNotEmpty) {
      await tester.enterText(partNameField, 'test part');
    } else {
      fail('Could not find Part Name field');
    }

    // Enter time (1:05)
    final minutesField = find.byKey(const Key('minutes_input'));
    final secondsField = find.byKey(const Key('seconds_input'));
    if (minutesField.evaluate().isNotEmpty && secondsField.evaluate().isNotEmpty) {
      await tester.enterText(minutesField, '1');
      await tester.enterText(secondsField, '05');
    } else {
      fail('Could not find time input fields');
    }

    // Tap the add time button
    final addTimeButton = find.byIcon(Icons.add);
    if (addTimeButton.evaluate().isNotEmpty) {
      await tester.tap(addTimeButton);
      await tester.pumpAndSettle();
    } else {
      fail('Could not find add time button');
    }

    // Verify the time chip is added
    expect(find.text('00:01:05'), findsOneWidget);

    // Save the opera
    final saveButton = find.widgetWithText(ElevatedButton, 'Save');
    if (saveButton.evaluate().isNotEmpty) {
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
    } else {
      fail('Could not find Save button');
    }

    // Verify we're back on the home screen and the new opera is listed
    expect(find.text('Test'), findsOneWidget);
  });
}
