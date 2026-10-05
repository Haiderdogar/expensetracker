abstract final class AppShellNavigationMetrics {
  static const bottomNavigationBarHeight = 62.0;
  static const buttonNavigationBottomPadding = 8.0;
  static const gestureNavigationBottomPadding = 1.0;
  static const floatingActionButtonGap = 16.0;
  static const floatingActionButtonDefaultMargin = 16.0;

  static double bottomNavigationPadding({required bool gestureNavigation}) =>
      gestureNavigation
      ? gestureNavigationBottomPadding
      : buttonNavigationBottomPadding;
}
