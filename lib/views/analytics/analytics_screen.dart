import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import 'analytics_filters_provider.dart';
import 'widgets/analytics_category_section.dart';
import 'widgets/analytics_custom_date_range.dart';
import 'widgets/analytics_summary_cards.dart';
import 'widgets/analytics_time_range_filter.dart';
import 'widgets/analytics_trend_section.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final accountCreatedAt = ref.watch(accountCreatedAtProvider).value;
    final isCustom = filter.timeRange == 'custom';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(AppStrings.analytics),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Unified Global Time Range Selector
          AnalyticsTimeRangeFilter(
            selected: filter.timeRange,
            onChanged: (range) {
              if (range == 'custom' && accountCreatedAt != null) {
                ref
                    .read(analyticsFilterProvider.notifier)
                    .setCustomRange(
                      filter.customStartDate ?? accountCreatedAt,
                      filter.customEndDate ?? DateTime.now(),
                    );
              } else {
                ref.read(analyticsFilterProvider.notifier).setTimeRange(range);
              }
            },
          ),

          // Custom Date Range Picker
          if (isCustom && accountCreatedAt != null) ...[
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
          const SizedBox(height: 10),

          // Key Performance Indicators / Financial Summary
          const AnalyticsSummaryCards(),
          const SizedBox(height: 10),

          // Category Breakdown (Pie chart + ranked category progress list)
          const AnalyticsCategorySection(),
          const SizedBox(height: 10),

          // Spending Trend (Continuous bar chart with zero-filling and interval labels)
          const AnalyticsTrendSection(),
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date cannot be later than end date'),
        ),
      );
      return;
    }

    if (!isStart && picked.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be earlier than start date'),
        ),
      );
      return;
    }

    final newStart = isStart ? picked : startDate;
    final newEnd = isStart ? endDate : picked;
    ref.read(analyticsFilterProvider.notifier).setCustomRange(newStart, newEnd);
  }
}
