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
    r'cd608724d3d944921c718785c63ecf30c4517342';

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
    r'60bea79eec8bb6905c325aec7453c657bcb913d4';

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
