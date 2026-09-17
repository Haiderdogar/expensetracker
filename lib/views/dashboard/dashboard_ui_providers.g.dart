// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecentTransactionFilter)
final recentTransactionFilterProvider = RecentTransactionFilterProvider._();

final class RecentTransactionFilterProvider
    extends $NotifierProvider<RecentTransactionFilter, String> {
  RecentTransactionFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentTransactionFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentTransactionFilterHash();

  @$internal
  @override
  RecentTransactionFilter create() => RecentTransactionFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$recentTransactionFilterHash() =>
    r'fe648397837cd4a1ef6cbd6d6c7892c4797f8936';

abstract class _$RecentTransactionFilter extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(DashboardBalanceHidden)
final dashboardBalanceHiddenProvider = DashboardBalanceHiddenProvider._();

final class DashboardBalanceHiddenProvider
    extends $NotifierProvider<DashboardBalanceHidden, bool> {
  DashboardBalanceHiddenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardBalanceHiddenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardBalanceHiddenHash();

  @$internal
  @override
  DashboardBalanceHidden create() => DashboardBalanceHidden();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$dashboardBalanceHiddenHash() =>
    r'e2e90f06643ff774f9adc5ddea46a0a9ca078296';

abstract class _$DashboardBalanceHidden extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
