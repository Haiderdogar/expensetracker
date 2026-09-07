import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../providers/database_provider.dart';

class AnalyticsFilter {
  const AnalyticsFilter({
    this.type = 'all',
    this.timeRange = 'week',
    this.customStartDate,
    this.customEndDate,
  });

  final String type;
  final String timeRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  AnalyticsFilter copyWith({
    String? type,
    String? timeRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return AnalyticsFilter(
      type: type ?? this.type,
      timeRange: timeRange ?? this.timeRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

final accountCreatedAtProvider = FutureProvider<DateTime>((ref) {
  return ref.watch(databaseHelperProvider).getAccountCreatedAt();
});

final categoryAnalyticsFilterProvider = StateProvider<AnalyticsFilter>(
  (ref) => const AnalyticsFilter(),
);

final trendAnalyticsFilterProvider = StateProvider<AnalyticsFilter>(
  (ref) => const AnalyticsFilter(),
);
