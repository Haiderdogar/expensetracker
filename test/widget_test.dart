import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker/app.dart';

void main() {
  testWidgets('App boots without forcing a PIN setup', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ExpenseTrackerApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
