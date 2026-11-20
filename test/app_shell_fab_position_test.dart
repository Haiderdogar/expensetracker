import 'package:expensetracker/views/app_shell/app_shell_bottom_navigation.dart';
import 'package:expensetracker/views/app_shell/app_shell_navigation_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final gestureNavigation in [false, true]) {
    for (final size in [const Size(400, 800), const Size(800, 400)]) {
      final navigationMode = gestureNavigation ? 'gesture' : 'button';
      final orientation = size.width > size.height ? 'landscape' : 'portrait';

      testWidgets(
        'FAB clears navigation without ad space in $navigationMode $orientation',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final bottomInset = gestureNavigation ? 12.0 : 24.0;
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    devicePixelRatio: 1,
                    padding: EdgeInsets.only(bottom: bottomInset),
                    viewPadding: EdgeInsets.only(bottom: bottomInset),
                  ),
                  child: Scaffold(
                    extendBody: true,
                    body: const SizedBox.expand(),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.endFloat,
                    floatingActionButton: const FloatingActionButton(
                      key: ValueKey('test-fab'),
                      onPressed: null,
                      child: Icon(Icons.add),
                    ),
                    bottomNavigationBar: AppShellBottomNavigation(
                      navigationModeLoader: () async => gestureNavigation,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final fabRect = tester.getRect(
            find.byKey(const ValueKey('test-fab')),
          );
          final navigationRect = tester.getRect(
            find.byType(AppShellBottomNavigation),
          );
          final expectedNavigationHeight =
              AppShellNavigationMetrics.bottomNavigationBarHeight +
              AppShellNavigationMetrics.bottomNavigationPadding(
                gestureNavigation: gestureNavigation,
              ) +
              bottomInset;

          expect(navigationRect.height, expectedNavigationHeight);
          expect(
            fabRect.bottom,
            closeTo(
              navigationRect.top -
                  AppShellNavigationMetrics.floatingActionButtonGap,
              0.01,
            ),
          );
          expect(fabRect.right, closeTo(size.width - 16, 0.01));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
