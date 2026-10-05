import 'package:expensetracker/views/app_shell/app_shell_navigation_metrics.dart';
import 'package:expensetracker/widgets/glass_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Scaffold keeps the active-tab FAB above the navbar in both modes',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var gestureNavigation = false;
      var bottomInset = 24.0;

      Widget buildApp() => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            devicePixelRatio: 1,
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: const FloatingActionButton(
              key: ValueKey('test-fab'),
              onPressed: null,
              child: Icon(Icons.add),
            ),
            bottomNavigationBar: GlassNavbar(
              currentIndex: 0,
              onTap: _ignoreTap,
              bottomPadding: AppShellNavigationMetrics.bottomNavigationPadding(
                gestureNavigation: gestureNavigation,
              ),
              items: [
                GlassNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                ),
              ],
            ),
          ),
        ),
      );

      Future<void> expectFabAboveNavbar() async {
        await tester.pumpAndSettle();
        final fabRect = tester.getRect(find.byKey(const ValueKey('test-fab')));
        final navbarRect = tester.getRect(
          find.byKey(const ValueKey('glass-navbar-surface')),
        );
        expect(
          fabRect.bottom,
          lessThanOrEqualTo(navbarRect.top - 16),
          reason: 'FAB $fabRect must clear navbar $navbarRect by at least 16px',
        );
      }

      await tester.pumpWidget(buildApp());
      await expectFabAboveNavbar();

      gestureNavigation = true;
      bottomInset = 12;
      await tester.pumpWidget(buildApp());
      await expectFabAboveNavbar();
    },
  );
}

void _ignoreTap(int _) {}
