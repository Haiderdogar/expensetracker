import 'dart:async';

import 'package:expensetracker/core/ads/ad_internet_status.dart';
import 'package:expensetracker/core/ads/admob_service.dart';
import 'package:expensetracker/core/ads/widgets/app_banner_ad.dart';
import 'package:expensetracker/models/category_model.dart';
import 'package:expensetracker/models/transaction_model.dart';
import 'package:expensetracker/providers/auth_provider.dart';
import 'package:expensetracker/providers/category_provider.dart';
import 'package:expensetracker/providers/transaction_provider.dart';
import 'package:expensetracker/views/transactions/add_transaction_screen.dart';
import 'package:expensetracker/views/transactions/transactions_ui_providers.dart';
import 'package:expensetracker/widgets/custom_button.dart';
import 'package:expensetracker/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
// Match the native SDK codec and registry without requesting live ads.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestAdMobService service;
  late ProviderContainer container;
  late StreamController<InternetStatus> internetChanges;
  late List<MethodCall> calls;
  InternetStatus? initialInternetStatus;

  Stream<InternetStatus> internetStatuses() async* {
    if (initialInternetStatus case final status?) yield status;
    yield* internetChanges.stream;
  }

  setUp(() {
    service = _TestAdMobService();
    internetChanges = StreamController<InternetStatus>.broadcast();
    initialInternetStatus = InternetStatus.connected;
    calls = [];
    container = ProviderContainer(
      overrides: [
        admobServiceProvider.overrideWithValue(service),
        adInternetStatusProvider.overrideWith((ref) => internetStatuses()),
        categoriesProvider.overrideWith(_TestCategories.new),
        transactionsProvider.overrideWith(_EmptyTransactions.new),
        currencySymbolProvider.overrideWith((ref) async => r'$'),
      ],
    );
    instanceManager = AdInstanceManager('plugins.flutter.io/google_mobile_ads');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getAdSize':
          final ad = instanceManager.adFor(call.arguments['adId']) as BannerAd;
          return AdSize(width: ad.size.width, height: 50);
        case 'loadBannerAd':
        case 'disposeAd':
          return null;
        default:
          throw StateError('Unexpected native call: ${call.method}');
      }
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'resize') {
        return <String, double>{
          'width': call.arguments['width'] as double,
          'height': call.arguments['height'] as double,
        };
      }
      return call.method == 'create' ? 0 : null;
    });
  });

  tearDown(() async {
    container.dispose();
    await internetChanges.close();
    service.dispose();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  Widget buildApp({String? initialType, TransactionModel? transaction}) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AddTransactionScreen(
            initialType: initialType,
            transaction: transaction,
          ),
        ),
      );

  BannerAd lastAd() {
    final load = calls.lastWhere((call) => call.method == 'loadBannerAd');
    return instanceManager.adFor(load.arguments['adId']) as BannerAd;
  }

  void setInternet(InternetStatus status) {
    initialInternetStatus = status;
    internetChanges.add(status);
  }

  void phoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(CustomTextField, label),
    matching: find.byType(TextFormField),
  );

  Future<void> removeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets(
    'new expense and income put the loaded ad above the form fields',
    (tester) async {
      phoneViewport(tester);
      for (final type in ['expense', 'income']) {
        await tester.pumpWidget(buildApp(initialType: type));
        await tester.pumpAndSettle();
        expect(container.read(transactionFormProvider(null)).type, type);
        final ad = lastAd();
        ad.listener.onAdLoaded!(ad);
        await tester.pumpAndSettle();

        final banner = tester.getRect(
          find.byKey(const ValueKey('admob-banner')),
        );
        final selector = tester.getRect(find.byType(SegmentedButton<String>));
        final category = tester.getRect(find.text('Category'));
        final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
        expect(banner.size, const Size(320, 50));
        expect(banner.top, appBarBottom + 2);
        expect(tester.getTopLeft(find.byType(ListView)).dy, appBarBottom + 54);
        expect(banner.bottom, lessThanOrEqualTo(selector.top));
        expect(selector.bottom, lessThan(category.top));
        expect(find.byType(AdWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
        await removeApp(tester);
      }
    },
  );

  testWidgets(
    'unknown and offline ads leave no gap and preserve entered data',
    (tester) async {
      phoneViewport(tester);
      initialInternetStatus = null;
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      final originalTop = tester
          .getTopLeft(find.byType(SegmentedButton<String>))
          .dy;
      final viewportTop = tester.getTopLeft(find.byType(ListView)).dy;
      expect(originalTop, viewportTop + 10);
      expect(service.initializationCalls, 0);
      expect(calls, isEmpty);

      await tester.enterText(field('Title'), 'Lunch');
      await tester.enterText(field('Amount'), '12.50');
      await tester.pumpAndSettle();
      setInternet(InternetStatus.disconnected);
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(find.byType(AdWidget), findsNothing);

      setInternet(InternetStatus.connected);
      await tester.pumpAndSettle();
      final ad = lastAd();
      ad.listener.onAdLoaded!(ad);
      await tester.pumpAndSettle();
      expect(find.byType(AdWidget), findsOneWidget);
      expect(container.read(transactionFormProvider(null)).title, 'Lunch');
      expect(container.read(transactionFormProvider(null)).amount, '12.50');
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('12.50'), findsOneWidget);

      setInternet(InternetStatus.disconnected);
      await tester.pumpAndSettle();
      expect(find.byType(AdWidget), findsNothing);
      expect(
        tester.getTopLeft(find.byType(SegmentedButton<String>)).dy,
        originalTop,
      );
      expect(container.read(transactionFormProvider(null)).title, 'Lunch');
      expect(container.read(transactionFormProvider(null)).amount, '12.50');
      expect(tester.takeException(), isNull);
      await removeApp(tester);
    },
  );

  testWidgets('banner stays pinned while the landscape form scrolls', (
    tester,
  ) async {
    phoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final first = lastAd();
    first.listener.onAdLoaded!(first);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    final rotated = lastAd();
    rotated.listener.onAdLoaded!(rotated);
    await tester.pumpAndSettle();
    final bannerBeforeKeyboard = tester.getRect(
      find.byKey(const ValueKey('admob-banner')),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('admob-banner'))),
      bannerBeforeKeyboard,
    );
    final requestsBeforeScroll = calls
        .where((call) => call.method == 'loadBannerAd')
        .length;
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byType(CustomButton),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byType(CustomButton));
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(ListView));
    final save = tester.getRect(find.byType(CustomButton));
    expect(save.top, greaterThanOrEqualTo(viewport.top));
    expect(save.bottom, lessThanOrEqualTo(viewport.bottom + 0.01));
    expect(save.bottom, lessThanOrEqualTo(220));
    expect(find.byType(AdWidget), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('admob-banner'))),
      bannerBeforeKeyboard,
    );
    expect(
      calls.where((call) => call.method == 'loadBannerAd'),
      hasLength(requestsBeforeScroll),
    );
    expect(tester.takeException(), isNull);
    await removeApp(tester);
  });

  testWidgets('a constrained keyboard viewport preserves the form draft', (
    tester,
  ) async {
    phoneViewport(tester);
    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final ad = lastAd();
    ad.listener.onAdLoaded!(ad);
    await tester.pumpAndSettle();
    await tester.ensureVisible(field('Title'));
    await tester.enterText(field('Title'), 'Travel');
    final editable = tester.widget<EditableText>(
      find.descendant(of: field('Title'), matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(find.byType(AppBannerAd), findsNothing);
    expect(calls.where((call) => call.method == 'disposeAd'), hasLength(1));
    expect(container.read(transactionFormProvider(null)).title, 'Travel');
    expect(editable.focusNode.hasFocus, isTrue);
    expect(find.text('Travel'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byType(CustomButton),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byType(CustomButton));
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(ListView));
    final save = tester.getRect(find.byType(CustomButton));
    expect(save.top, greaterThanOrEqualTo(viewport.top));
    expect(save.bottom, lessThanOrEqualTo(viewport.bottom + 0.01));
    expect(tester.takeException(), isNull);
    await removeApp(tester);
  });

  testWidgets('editing a transaction does not mount or initialize an ad', (
    tester,
  ) async {
    phoneViewport(tester);
    const transaction = TransactionModel(
      id: 'transaction-1',
      title: 'Groceries',
      amount: 25.75,
      type: 'expense',
      categoryId: 'food',
      walletId: 'wallet-1',
      date: '2026-11-20T10:00:00.000',
    );
    await tester.pumpWidget(buildApp(transaction: transaction));
    await tester.pumpAndSettle();

    expect(find.text('Edit Expense'), findsOneWidget);
    expect(find.byType(AppBannerAd), findsNothing);
    expect(find.byType(AdWidget), findsNothing);
    expect(service.initializationCalls, 0);
    expect(calls, isEmpty);
    expect(find.text('Groceries'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await removeApp(tester);
  });
}

class _TestAdMobService extends AdMobService {
  int initializationCalls = 0;

  @override
  bool get isSupported => true;

  @override
  bool get canRequestAds => true;

  @override
  bool get isShowingPrivacyOptions => false;

  @override
  bool get needsInitializationRetry => false;

  @override
  Future<void> initialize() async {
    initializationCalls++;
  }
}

class _TestCategories extends Categories {
  @override
  Future<List<CategoryModel>> build() async => const [
    CategoryModel(
      id: 'food',
      name: 'Food',
      type: 'expense',
      icon: 'restaurant',
      color: '#EF4444',
    ),
    CategoryModel(
      id: 'salary',
      name: 'Salary',
      type: 'income',
      icon: 'payments',
      color: '#10B981',
    ),
  ];
}

class _EmptyTransactions extends Transactions {
  @override
  Future<List<TransactionModel>> build() async => const [];
}
