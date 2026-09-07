import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../analytics_date_range.dart';
import '../analytics_filters_provider.dart';
import 'analytics_custom_date_range.dart';
import 'analytics_time_range_filter.dart';
import 'analytics_type_filter.dart';

class AnalyticsChartSection extends StatelessWidget {
  const AnalyticsChartSection({
    super.key,
    required this.title,
    required this.filterProvider,
    required this.chartBuilder,
  });

  final String title;
  final StateProvider<AnalyticsFilter> filterProvider;
  final Widget Function(String typeFilter, DateTime rangeStart, DateTime rangeEnd)
  chartBuilder;

  @override
  Widget build(BuildContext context) {
    // Only this section listens to its filter state; the screen stays static.
    return Consumer(
      builder: (context, ref, _) {
        final filter = ref.watch(filterProvider);
        final accountCreatedAt = ref.watch(accountCreatedAtProvider).value;
        final rangeStart = analyticsRangeStart(
          filter.timeRange,
          filter.customStartDate,
        );
        final rangeEnd = analyticsRangeEnd(filter.timeRange, filter.customEndDate);
        final isCustomRange = filter.timeRange == 'custom';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            AnalyticsTypeFilter(
              selected: filter.type,
              onChanged: (type) => _updateFilter(ref, filter.copyWith(type: type)),
            ),
            const SizedBox(height: 14),
            AnalyticsTimeRangeFilter(
              selected: filter.timeRange,
              onChanged: (timeRange) => _selectTimeRange(
                ref,
                filter,
                timeRange,
                accountCreatedAt,
              ),
            ),
            if (isCustomRange && accountCreatedAt != null) ...[
              const SizedBox(height: 12),
              AnalyticsCustomDateRange(
                startDate: filter.customStartDate ?? accountCreatedAt,
                endDate: filter.customEndDate ?? DateTime.now(),
                onStartDateTap: () => _pickDate(
                  context: context,
                  ref: ref,
                  filter: filter,
                  accountCreatedAt: accountCreatedAt,
                  isStart: true,
                ),
                onEndDateTap: () => _pickDate(
                  context: context,
                  ref: ref,
                  filter: filter,
                  accountCreatedAt: accountCreatedAt,
                  isStart: false,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: chartBuilder(filter.type, rangeStart, rangeEnd),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateFilter(WidgetRef ref, AnalyticsFilter filter) {
    ref.read(filterProvider.notifier).state = filter;
  }

  void _selectTimeRange(
    WidgetRef ref,
    AnalyticsFilter filter,
    String timeRange,
    DateTime? accountCreatedAt,
  ) {
    final isCustom = timeRange == 'custom';
    _updateFilter(
      ref,
      AnalyticsFilter(
        type: filter.type,
        timeRange: timeRange,
        customStartDate: isCustom ? accountCreatedAt : filter.customStartDate,
        customEndDate: isCustom ? DateTime.now() : filter.customEndDate,
      ),
    );
  }

  Future<void> _pickDate({
    required BuildContext context,
    required WidgetRef ref,
    required AnalyticsFilter filter,
    required DateTime accountCreatedAt,
    required bool isStart,
  }) async {
    final now = DateTime.now();
    final startDate = filter.customStartDate ?? accountCreatedAt;
    final endDate = filter.customEndDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: isStart ? accountCreatedAt : startDate,
      lastDate: isStart ? endDate : now,
    );
    if (picked == null || !context.mounted) return;

    if (isStart && picked.isAfter(endDate)) {
      _showInvalidDateMessage(context, 'Start date cannot be later than the end date.');
      return;
    }
    if (!isStart && picked.isBefore(startDate)) {
      _showInvalidDateMessage(context, 'End date cannot be earlier than the start date.');
      return;
    }
    _updateFilter(
      ref,
      isStart
          ? filter.copyWith(customStartDate: picked)
          : filter.copyWith(customEndDate: picked),
    );
  }

  void _showInvalidDateMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
