// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BackupService)
final backupServiceProvider = BackupServiceProvider._();

final class BackupServiceProvider
    extends $NotifierProvider<BackupService, void> {
  BackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupServiceHash();

  @$internal
  @override
  BackupService create() => BackupService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$backupServiceHash() => r'bc512dcbfe5fdc5addad674180284ed0ccb709e6';

abstract class _$BackupService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(expenseByCategory)
final expenseByCategoryProvider = ExpenseByCategoryProvider._();

final class ExpenseByCategoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, double>>,
          Map<String, double>,
          FutureOr<Map<String, double>>
        >
    with
        $FutureModifier<Map<String, double>>,
        $FutureProvider<Map<String, double>> {
  ExpenseByCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseByCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseByCategoryHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, double>> create(Ref ref) {
    return expenseByCategory(ref);
  }
}

String _$expenseByCategoryHash() => r'901eb6642e9fa7fadcd53f0938379b15f303349b';

@ProviderFor(monthlySpendingTrend)
final monthlySpendingTrendProvider = MonthlySpendingTrendProvider._();

final class MonthlySpendingTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MapEntry<String, double>>>,
          List<MapEntry<String, double>>,
          FutureOr<List<MapEntry<String, double>>>
        >
    with
        $FutureModifier<List<MapEntry<String, double>>>,
        $FutureProvider<List<MapEntry<String, double>>> {
  MonthlySpendingTrendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlySpendingTrendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlySpendingTrendHash();

  @$internal
  @override
  $FutureProviderElement<List<MapEntry<String, double>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MapEntry<String, double>>> create(Ref ref) {
    return monthlySpendingTrend(ref);
  }
}

String _$monthlySpendingTrendHash() =>
    r'9f3a6b4ed1f9aec2a2e754e0f5a5b91f3d471fcd';
