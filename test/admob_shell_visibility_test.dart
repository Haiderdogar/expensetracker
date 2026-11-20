import 'package:expensetracker/core/ads/admob_service.dart';
import 'package:expensetracker/core/ads/widgets/app_banner_ad.dart';
import 'package:expensetracker/features/wallet_currency/providers/wallet_provider.dart';
import 'package:expensetracker/models/transaction_model.dart';
import 'package:expensetracker/models/wallet_model.dart';
import 'package:expensetracker/providers/auth_provider.dart';
import 'package:expensetracker/providers/transaction_provider.dart';
import 'package:expensetracker/views/app_shell.dart';
import 'package:expensetracker/views/app_shell/app_shell_bottom_navigation.dart';
import 'package:expensetracker/views/app_shell/app_shell_providers.dart';
import 'package:expensetracker/views/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const navigationChannel = MethodChannel('android_nav_setting');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(navigationChannel, (call) async {
          expect(call.method, 'getNavigationMode');
          return 0;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(navigationChannel, null);
  });

  testWidgets('shell tabs and drawer routes do not mount advertising', (
    tester,
  ) async {
    // Match the existing Dashboard smoke test. Its header uses the wider Ahem
    // test font; phone-size FAB geometry is covered separately.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _DisabledAdMobService();
    addTearDown(service.dispose);
    final container = ProviderContainer(
      overrides: [
        admobServiceProvider.overrideWithValue(service),
        currentUserIdProvider.overrideWithValue(''),
        appShellProfileProvider.overrideWith(
          (ref) async => const AppShellProfile(name: '', email: ''),
        ),
        walletsProvider.overrideWith(_EmptyWallets.new),
        transactionsProvider.overrideWith(_EmptyTransactions.new),
        currencySymbolProvider.overrideWith((ref) async => r'$'),
      ],
    );
    addTearDown(container.dispose);

    var isHome = true;
    Widget buildApp() => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: AppShellRoute(
          isHome: isHome,
          child: isHome
              ? const SizedBox.expand()
              : const Scaffold(body: Text('Drawer destination')),
        ),
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final shellState = tester.state(find.byType(AppShell));
    expect(find.byType(AppBannerAd), findsNothing);

    // Check the actual shell-provided inset, rather than an independently
    // reconstructed Dashboard layout. The final spacer clears the measured
    // bottom bar and the standard FAB plus its surrounding gaps.
    final dashboardScroll = tester.widget<CustomScrollView>(
      find.descendant(
        of: find.byType(DashboardScreen),
        matching: find.byType(CustomScrollView),
      ),
    );
    final spacer =
        (dashboardScroll.slivers.last as SliverToBoxAdapter).child! as SizedBox;
    final bottomBarHeight = tester
        .getSize(find.byType(AppShellBottomNavigation))
        .height;
    expect(spacer.height, bottomBarHeight + 88);

    for (final tab in [1, 2, 3]) {
      container.read(appShellNavigationIndexProvider.notifier).setIndex(tab);
      await tester.pumpAndSettle();
      expect(find.byType(AppBannerAd), findsNothing);
    }

    container.read(appShellNavigationIndexProvider.notifier).setIndex(0);
    await tester.pumpAndSettle();
    expect(find.byType(AppBannerAd), findsNothing);

    isHome = false;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Drawer destination'), findsOneWidget);
    expect(find.byType(AppBannerAd), findsNothing);
    expect(tester.state(find.byType(AppShell)), same(shellState));

    isHome = true;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.byType(AppBannerAd), findsNothing);
    expect(tester.state(find.byType(AppShell)), same(shellState));
    expect(service.initializationCalls, 0);
    expect(tester.takeException(), isNull);

    // Release widget listeners before disposing the externally owned container.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _DisabledAdMobService extends AdMobService {
  int initializationCalls = 0;

  @override
  bool get isSupported => false;

  @override
  Future<void> initialize() async {
    initializationCalls++;
  }
}

class _EmptyWallets extends Wallets {
  @override
  Future<List<WalletModel>> build() async => const [];
}

class _EmptyTransactions extends Transactions {
  @override
  Future<List<TransactionModel>> build() async => const [];
}
