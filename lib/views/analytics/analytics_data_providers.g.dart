// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(analyticsDateRangeData)
final analyticsDateRangeDataProvider = AnalyticsDateRangeDataProvider._();

final class AnalyticsDateRangeDataProvider
    extends
        $FunctionalProvider<
          DateTimeRange<DateTime>,
          DateTimeRange<DateTime>,
          DateTimeRange<DateTime>
        >
    with $Provider<DateTimeRange<DateTime>> {
  AnalyticsDateRangeDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsDateRangeDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsDateRangeDataHash();

  @$internal
  @override
  $ProviderElement<DateTimeRange<DateTime>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTimeRange<DateTime> create(Ref ref) {
    return analyticsDateRangeData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTimeRange<DateTime> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTimeRange<DateTime>>(value),
    );
  }
}

String _$analyticsDateRangeDataHash() =>
    r'd4e28ac9743e9cbd7046c8c3031a37d8e55d8a85';

@ProviderFor(categoryBreakdown)
final categoryBreakdownProvider = CategoryBreakdownProvider._();

final class CategoryBreakdownProvider
    extends
        $FunctionalProvider<
          CategoryBreakdownData,
          CategoryBreakdownData,
          CategoryBreakdownData
        >
    with $Provider<CategoryBreakdownData> {
  CategoryBreakdownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryBreakdownProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryBreakdownHash();

  @$internal
  @override
  $ProviderElement<CategoryBreakdownData> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryBreakdownData create(Ref ref) {
    return categoryBreakdown(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryBreakdownData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryBreakdownData>(value),
    );
  }
}

String _$categoryBreakdownHash() => r'b4c507953fc2674b611b38b29f53f9354214ef51';

@ProviderFor(analyticsSummary)
final analyticsSummaryProvider = AnalyticsSummaryProvider._();

final class AnalyticsSummaryProvider
    extends
        $FunctionalProvider<
          AnalyticsSummary,
          AnalyticsSummary,
          AnalyticsSummary
        >
    with $Provider<AnalyticsSummary> {
  AnalyticsSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsSummaryHash();

  @$internal
  @override
  $ProviderElement<AnalyticsSummary> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnalyticsSummary create(Ref ref) {
    return analyticsSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsSummary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsSummary>(value),
    );
  }
}

String _$analyticsSummaryHash() => r'39aaa48114766b9fe308d47ae16e9c5a825bca3f';

@ProviderFor(trendSeries)
final trendSeriesProvider = TrendSeriesProvider._();

final class TrendSeriesProvider
    extends
        $FunctionalProvider<
          List<TrendBucket>,
          List<TrendBucket>,
          List<TrendBucket>
        >
    with $Provider<List<TrendBucket>> {
  TrendSeriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendSeriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendSeriesHash();

  @$internal
  @override
  $ProviderElement<List<TrendBucket>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TrendBucket> create(Ref ref) {
    return trendSeries(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TrendBucket> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TrendBucket>>(value),
    );
  }
}

String _$trendSeriesHash() => r'0fa8bf1bedd34d3823945a21d3fa90cfb7b5ce87';

@ProviderFor(PieChartTouchedIndex)
final pieChartTouchedIndexProvider = PieChartTouchedIndexProvider._();

final class PieChartTouchedIndexProvider
    extends $NotifierProvider<PieChartTouchedIndex, int?> {
  PieChartTouchedIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pieChartTouchedIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pieChartTouchedIndexHash();

  @$internal
  @override
  PieChartTouchedIndex create() => PieChartTouchedIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$pieChartTouchedIndexHash() =>
    r'12a64c3fc0e3fbc95d36777d5e097eeec4b7e306';

abstract class _$PieChartTouchedIndex extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
