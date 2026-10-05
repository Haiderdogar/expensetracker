import 'dart:async';

import 'package:android_nav_setting/android_nav_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../widgets/glass_navbar.dart';
import 'app_shell_navigation_metrics.dart';
import 'app_shell_providers.dart';

class AppShellBottomNavigation extends ConsumerStatefulWidget {
  const AppShellBottomNavigation({
    super.key,
    this.navigationModeLoader,
  });

  @visibleForTesting
  final Future<bool> Function()? navigationModeLoader;

  @override
  ConsumerState<AppShellBottomNavigation> createState() =>
      _AppShellBottomNavigationState();
}

class _AppShellBottomNavigationState
    extends ConsumerState<AppShellBottomNavigation>
    with WidgetsBindingObserver {
  final _navigationSetting = AndroidNavSetting();
  bool _isGestureNavigationEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshNavigationMode());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshNavigationMode());
    }
  }

  Future<void> _refreshNavigationMode() async {
    final isGestureNavigationEnabled =
        await (widget.navigationModeLoader?.call() ??
            _navigationSetting.isGestureNavigationEnabled());
    if (!mounted || isGestureNavigationEnabled == _isGestureNavigationEnabled) {
      return;
    }

    setState(() {
      _isGestureNavigationEnabled = isGestureNavigationEnabled;
    });
  }

  static const _items = [
    GlassNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: AppStrings.dashboard),
    GlassNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: AppStrings.transactions),
    GlassNavItem(icon: Icons.pie_chart_outline, activeIcon: Icons.pie_chart, label: AppStrings.analytics),
    GlassNavItem(icon: Icons.savings_outlined, activeIcon: Icons.savings, label: AppStrings.budgets),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassNavbar(
      currentIndex: ref.watch(appShellNavigationIndexProvider),
      items: _items,
      bottomPadding: AppShellNavigationMetrics.bottomNavigationPadding(
        gestureNavigation: _isGestureNavigationEnabled,
      ),
      onTap: (index) {
        ref.read(appShellNavigationIndexProvider.notifier).state = index;
        ref.read(appShellVisitedIndexesProvider.notifier).addIndex(index);
      },
    );
  }
}
