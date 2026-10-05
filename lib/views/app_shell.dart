import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/utils/global_keys.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import 'app_shell/app_shell_providers.dart';
import 'app_shell/app_shell_bottom_navigation.dart';
import 'app_shell/app_shell_drawer.dart';
import 'app_shell/app_shell_navigation_body.dart';
import 'budgets/budgets_screen.dart';
import 'budgets/widgets/budgets_add_button.dart';
import 'dashboard/widgets/dashboard_add_transaction_button.dart';
import 'transactions/widgets/transactions_add_button.dart';

/// The application chrome. Owns the sync-on-resume lifecycle hook.
///
/// ── Rebuild guarantee ────────────────────────────────────────────────────────
/// This widget NEVER rebuilds itself due to provider state changes.
/// Every safeguard that enforces this is listed below:
///
/// 1. `build()` calls zero `ref.watch()` — no provider subscriptions are
///    created, so no provider change can ever schedule a rebuild of this widget.
///
/// 2. `_AppShellScaffold` watches only the active tab. Data providers are
///    watched in their respective feature widgets, keeping tab changes from
///    rebuilding the lifecycle/sync owner.
///
/// 3. `_syncOnResume()` uses only `ref.read()` — fire-and-forget reads that
///    create no subscriptions. The epoch bump via `localDataEpochProvider` is
///    **conditional**: it only fires when `syncOnAppOpen` returns `true`
///    (i.e. new records were actually pulled from Firestore). On the common
///    fast path (version unchanged / offline) the bump is skipped entirely,
///    so the dashboard loads exactly once on every cold start.
///
/// 4. `_syncOnResume()` never calls `setState()` — the lifecycle observer
///    hook triggers background async work without touching Flutter's widget
///    rebuild mechanism for this widget.
/// ─────────────────────────────────────────────────────────────────────────────
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Run the initial manifest check after the first frame is committed so it
    // never delays the first render. unawaited is intentional — we never want
    // background sync work to block the UI.
    unawaited(_syncOnResume());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Fires every time the app transitions from background → foreground.
  /// Only the resumed state matters for sync; paused/detached/inactive are
  /// no-ops here.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncOnResume());
    }
  }

  /// Sync trigger: push pending local changes, then run the ultra-low-cost
  /// manifest check (1 Firestore read when nothing changed on other devices).
  ///
  /// Uses `ref.read()` exclusively — creates zero provider subscriptions and
  /// never causes this widget to rebuild. After the sync completes, bumps
  /// [LocalDataEpoch] so only the data providers that subscribe to it
  /// (transactions, categories, etc.) re-fetch from the updated SQLite.
  Future<void> _syncOnResume() async {
    // ref.read — no subscription, no rebuild of this widget.
    final userId = ref.read(currentUserIdProvider);
    if (userId.isEmpty) return;

    // ref.read — no subscription, no rebuild of this widget.
    final syncRepo = ref.read(syncRepositoryProvider);

    // syncOnAppOpen returns true only when new records were actually pulled
    // from Firestore into SQLite. On the fast path (version unchanged or
    // offline) it returns false — no bump needed, no UI reload triggered.
    final hadChanges = await syncRepo.syncOnAppOpen(userId);

    // mounted check prevents calling ref after dispose (async gap safety).
    if (!mounted) return;

    // Only bump the epoch (and cause data providers to re-query SQLite) when
    // the sync actually merged new data. This eliminates the spurious second
    // dashboard load that happened on every cold start when nothing changed.
    if (hadChanges) {
      ref.read(localDataEpochProvider.notifier).bump();
    }
  }

  /// The lifecycle/sync owner does not subscribe to tab navigation state.
  @override
  Widget build(BuildContext context) => const _AppShellScaffold();
}

class _AppShellScaffold extends ConsumerWidget {
  const _AppShellScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(appShellNavigationIndexProvider);

    return Scaffold(
      key: appShellScaffoldKey,
      drawer: const AppShellDrawer(),
      body: const AppShellNavigationBody(),
      extendBody: true,
      bottomNavigationBar: const AppShellBottomNavigation(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: switch (selectedTab) {
        0 => const DashboardAddTransactionButton(),
        1 => const TransactionsAddButton(),
        3 => BudgetsAddButton(
          onPressed: () => BudgetsScreen.showAddBudget(context),
        ),
        _ => null,
      },
    );
  }
}
