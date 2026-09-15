import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/database_provider.dart';

part 'analytics_filters_provider.g.dart';

class AnalyticsFilter {
  const AnalyticsFilter({
    this.timeRange = 'month',
    this.categoryType = 'expense',
    this.trendType = 'all',
    this.customStartDate,
    this.customEndDate,
  });

  final String timeRange;
  final String categoryType; // 'expense' or 'income' for Category breakdown
  final String trendType; // 'all', 'expense', or 'income' for Trend chart
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  AnalyticsFilter copyWith({
    String? timeRange,
    String? categoryType,
    String? trendType,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return AnalyticsFilter(
      timeRange: timeRange ?? this.timeRange,
      categoryType: categoryType ?? this.categoryType,
      trendType: trendType ?? this.trendType,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

@riverpod
Future<DateTime> accountCreatedAt(Ref ref) {
  return ref.watch(databaseHelperProvider).getAccountCreatedAt();
}

@riverpod
class AnalyticsFilterNotifier extends _$AnalyticsFilterNotifier {
  @override
  AnalyticsFilter build() => const AnalyticsFilter();

  void setTimeRange(String range) {
    state = state.copyWith(timeRange: range);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      timeRange: 'custom',
      customStartDate: start,
      customEndDate: end,
    );
  }

  void setCategoryType(String type) {
    state = state.copyWith(categoryType: type);
  }

  void setTrendType(String type) {
    state = state.copyWith(trendType: type);
  }
}
