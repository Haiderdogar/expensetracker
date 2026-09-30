import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/global_keys.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import 'app_shell/app_shell_bottom_navigation.dart';
import 'app_shell/app_shell_drawer.dart';
import 'app_shell/app_shell_navigation_body.dart';

/// The application chrome. Owns the sync-on-resume lifecycle hook.
///
/// ── Rebuild guarantee ────────────────────────────────────────────────────────
/// This widget NEVER rebuilds itself due to provider state changes.
/// Every safeguard that enforces this is listed below:
///
/// 1. `build()` calls zero `ref.watch()` — no provider subscriptions are
///    created, so no provider change can ever schedule a rebuild of this widget.
///
/// 2. All scaffold children (`AppShellDrawer`, `AppShellNavigationBody`,
///    `AppShellBottomNavigation`) are `const` — Flutter's element-tree diffing
///    identifies them as the same instances on every build call and skips them.
///    Each child manages its own provider subscriptions and rebuild scope
///    independently.
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

  /// build() has ZERO ref.watch() calls — this widget is rebuild-free.
  /// Each const child owns its own rebuild scope via its own ConsumerWidget.
  @override
  Widget build(BuildContext context) => Scaffold(
    key: appShellScaffoldKey,
    drawer: const AppShellDrawer(),
    body: const AppShellNavigationBody(),
    extendBody: true,
    bottomNavigationBar: const AppShellBottomNavigation(),
  );
}
