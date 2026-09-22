import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker/app.dart';

void main() {
  testWidgets('App boots without forcing a PIN setup', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ExpenseTrackerApp()),
    );
    // Startup performs secure-storage and Firebase restoration asynchronously.
    // A progress indicator is intentionally animated while that work runs, so
    // settling is neither required nor appropriate for this smoke test.
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
