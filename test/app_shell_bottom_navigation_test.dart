import 'package:expensetracker/views/app_shell/app_shell_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';



void main() {
  testWidgets(
    'uses button and gesture bottom padding and refreshes on resume',
    (tester) async {
      var isGestureNavigationEnabled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: AppShellBottomNavigation(
                navigationModeLoader: () async => isGestureNavigationEnabled,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Padding navbarPadding() =>
          tester.widget(find.byKey(const ValueKey('glass-navbar-padding')));

      expect(navbarPadding().padding, const EdgeInsets.fromLTRB(16, 0, 16, 8));

      isGestureNavigationEnabled = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(navbarPadding().padding, const EdgeInsets.fromLTRB(16, 0, 16, 1));
    },
  );
}
