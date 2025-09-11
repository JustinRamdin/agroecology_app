import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agroecology_app/main.dart';

void main() {
  testWidgets('App builds and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AgroApp());

    // Simple sanity checks for your current UI:
    expect(find.text('Agroecology App'), findsOneWidget);
    // If you render 'Log Planting' button on startup:
    expect(find.text('Log Planting'), findsOneWidget);
  });
}
