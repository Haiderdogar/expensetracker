import 'dart:async';

import 'package:expensetracker/app/app_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _application = MaterialApp(
  home: Scaffold(body: Text('Application ready')),
);

void main() {
  testWidgets('waits for required initialization before mounting the app', (
    tester,
  ) async {
    final initialization = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(
      AppBootstrap(
        initialize: () {
          calls++;
          return initialization.future;
        },
        child: _application,
      ),
    );

    expect(calls, 1);
    expect(find.text('Application ready'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    initialization.complete();
    await tester.pump();

    expect(find.text('Application ready'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('reports failed prerequisites and keeps the app inaccessible', (
    tester,
  ) async {
    final initialization = Completer<void>();
    final errors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    var errorFrames = 0;

    try {
      await tester.pumpWidget(
        AppBootstrap(
          initialize: () => initialization.future,
          onInitializationFailure: () {
            expect(find.text('Retry'), findsOneWidget);
            errorFrames++;
          },
          child: _application,
        ),
      );

      final failure = StateError('Secure storage is unavailable');
      initialization.completeError(failure, StackTrace.current);
      await tester.pump();

      expect(find.text('Application ready'), findsNothing);
      expect(
        find.text('Unable to start Expensee. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(errorFrames, 1);
      expect(errors, hasLength(1));
      expect(errors.single.exception, same(failure));
      expect(errors.single.stack, isNotNull);
      expect(find.textContaining('Secure storage'), findsNothing);
    } finally {
      FlutterError.onError = previousHandler;
    }
  });

  testWidgets('Retry reruns prerequisites and waits for them to succeed', (
    tester,
  ) async {
    final attempts = [Completer<void>(), Completer<void>()];
    final errors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    var calls = 0;

    try {
      await tester.pumpWidget(
        AppBootstrap(
          initialize: () => attempts[calls++].future,
          child: _application,
        ),
      );
      attempts.first.completeError(StateError('Database is unavailable'));
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(calls, 2);
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Application ready'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      attempts.last.complete();
      await tester.pump();

      expect(find.text('Application ready'), findsOneWidget);
      expect(errors, hasLength(1));
    } finally {
      FlutterError.onError = previousHandler;
    }
  });
}
