// Widget tests for the PC Maintenance Tracker home & detail screens.
//
// These test HomeScreen and PcDetailScreen directly, wrapped in their own
// MaterialApp, rather than going through PcMaintenanceApp/AuthGate. AuthGate
// depends on Supabase.instance.client, which is only initialized in main()
// — pumping the full app here would throw before a single frame renders.
// Auth-flow behavior (login/signup) belongs in its own test file that
// fakes or mocks the Supabase client instead of hitting the real one.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pc_maintenance_tracker/models/virtual_pc.dart';
import 'package:pc_maintenance_tracker/screens/home_screen.dart';
import 'package:pc_maintenance_tracker/screens/pc_detail_screen.dart';

void main() {
  testWidgets('Home screen shows the list of mock PCs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // The header text should be visible.
    expect(find.text('Your PCs'), findsOneWidget);

    // Every mock PC's name should show up as a card.
    for (final pc in mockPcs) {
      expect(find.text(pc.name), findsOneWidget);
    }

    // The "Add a PC" button should be present.
    expect(find.text('Add a PC'), findsOneWidget);
  });

  testWidgets('Tapping a PC card navigates to its detail screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final firstPc = mockPcs.first;
    await tester.tap(find.text(firstPc.name));
    await tester.pumpAndSettle(); // let the push transition finish

    // We should now be on the detail screen for that PC.
    expect(find.byType(PcDetailScreen), findsOneWidget);
    expect(
      find.text('Next cleaning predicted in ${firstPc.nextCleaningInDays} days'),
      findsOneWidget,
    );
  });
}