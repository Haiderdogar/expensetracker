// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_filters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountCreatedAt)
final accountCreatedAtProvider = AccountCreatedAtProvider._();

final class AccountCreatedAtProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, FutureOr<DateTime>>
    with $FutureModifier<DateTime>, $FutureProvider<DateTime> {
  AccountCreatedAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountCreatedAtProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountCreatedAtHash();

  @$internal
  @override
  $FutureProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DateTime> create(Ref ref) {
    return accountCreatedAt(ref);
  }
}

String _$accountCreatedAtHash() => r'6fa6077983b7128b81b513d73976c535e2012353';

@ProviderFor(AnalyticsFilterNotifier)
final analyticsFilterProvider = AnalyticsFilterNotifierProvider._();

final class AnalyticsFilterNotifierProvider
    extends $NotifierProvider<AnalyticsFilterNotifier, AnalyticsFilter> {
  AnalyticsFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsFilterNotifierHash();

  @$internal
  @override
  AnalyticsFilterNotifier create() => AnalyticsFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsFilter>(value),
    );
  }
}

String _$analyticsFilterNotifierHash() =>
    r'19a53638f87b7c9e7ea017a2e0217c22db8d791e';

abstract class _$AnalyticsFilterNotifier extends $Notifier<AnalyticsFilter> {
  AnalyticsFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AnalyticsFilter, AnalyticsFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnalyticsFilter, AnalyticsFilter>,
              AnalyticsFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
