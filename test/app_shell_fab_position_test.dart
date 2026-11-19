import 'package:expensetracker/views/app_shell/app_shell_bottom_bar.dart';
import 'package:expensetracker/views/app_shell/app_shell_navigation_metrics.dart';
import 'package:expensetracker/widgets/glass_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final gestureNavigation in [false, true]) {
    for (final size in [const Size(400, 800), const Size(800, 400)]) {
      final navigationMode = gestureNavigation ? 'gesture' : 'button';
      final orientation = size.width > size.height ? 'landscape' : 'portrait';

      testWidgets(
        'FAB follows loaded banner height and restores in $navigationMode $orientation',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final bottomInset = gestureNavigation ? 12.0 : 24.0;
          double? bannerHeight;

          Widget buildApp() => MaterialApp(
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
                bottomNavigationBar: AppShellBottomBar(
                  key: const ValueKey('test-bottom-bar'),
                  // An unfilled/removed banner has zero height. This uses the
                  // production bottom-bar composition without platform views.
                  banner: bannerHeight == null
                      ? null
                      : SizedBox(
                          key: const ValueKey('test-banner'),
                          height: bannerHeight,
                        ),
                  navigation: GlassNavbar(
                    currentIndex: 0,
                    onTap: _ignoreTap,
                    bottomPadding:
                        AppShellNavigationMetrics.bottomNavigationPadding(
                          gestureNavigation: gestureNavigation,
                        ),
                    items: const [
                      GlassNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: 'Home',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          Future<Rect> pumpAndCheckClearance() async {
            await tester.pumpWidget(buildApp());
            await tester.pumpAndSettle();
            final fabRect = tester.getRect(
              find.byKey(const ValueKey('test-fab')),
            );
            final bottomBarRect = tester.getRect(
              find.byKey(const ValueKey('test-bottom-bar')),
            );
            expect(
              fabRect.bottom,
              closeTo(
                bottomBarRect.top -
                    AppShellNavigationMetrics.floatingActionButtonGap,
                0.01,
              ),
              reason: 'FAB must clear both the banner and navigation',
            );
            if (bannerHeight != null && bannerHeight > 0) {
              final bannerRect = tester.getRect(
                find.byKey(const ValueKey('test-banner')),
              );
              final navbarRect = tester.getRect(
                find.byKey(const ValueKey('glass-navbar-surface')),
              );
              expect(bannerRect.height, bannerHeight);
              expect(bannerRect.bottom, lessThanOrEqualTo(navbarRect.top));
              expect(fabRect.overlaps(bannerRect), isFalse);
            }
            expect(tester.takeException(), isNull);
            return fabRect;
          }

          final originalFabRect = await pumpAndCheckClearance();

          // Loading and no-fill states do not reserve any banner space.
          bannerHeight = 0;
          expect(await pumpAndCheckClearance(), originalFabRect);

          for (final loadedHeight in [50.0, 150.0]) {
            bannerHeight = loadedHeight;
            final loadedFabRect = await pumpAndCheckClearance();
            expect(
              loadedFabRect.bottom,
              closeTo(originalFabRect.bottom - loadedHeight, 0.01),
            );
          }

          // A failure/reload removes occupied space immediately; leaving the
          // Dashboard removes the banner widget altogether with the same result.
          bannerHeight = 0;
          expect(await pumpAndCheckClearance(), originalFabRect);
          bannerHeight = null;
          expect(await pumpAndCheckClearance(), originalFabRect);
        },
      );
    }
  }
}

void _ignoreTap(int _) {}
