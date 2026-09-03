import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/global_keys.dart';
import '../../providers/database_provider.dart';
import 'widgets/expense_pie_chart.dart';
import 'widgets/spending_bar_chart.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _categoryTypeFilter = 'all';
  String _trendTypeFilter = 'all';
  String _categoryTimeRange = 'week';
  String _trendTimeRange = 'week';
  DateTime? _categoryCustomStartDate;
  DateTime? _categoryCustomEndDate;
  DateTime? _trendCustomStartDate;
  DateTime? _trendCustomEndDate;
  DateTime? _accountCreatedAt;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
  }

  Future<void> _setDefaultDates() async {
    final now = DateTime.now();
    final createdAt = await ref
        .read(databaseHelperProvider)
        .getAccountCreatedAt();
    if (!mounted) return;
    setState(() {
      _accountCreatedAt = createdAt;
      _categoryCustomStartDate = createdAt;
      _categoryCustomEndDate = now;
      _trendCustomStartDate = createdAt;
      _trendCustomEndDate = now;
      _initialized = true;
    });
  }

  DateTime _rangeStartFor(String timeRange, DateTime? customStartDate) {
    final now = DateTime.now();
    switch (timeRange) {
      case 'day':
        return now.subtract(const Duration(days: 1));
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month - 1, now.day);
      case 'quarter':
        return DateTime(now.year, now.month - 3, now.day);
      case 'custom':
        return customStartDate ?? now;
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  DateTime _rangeEndFor(String timeRange, DateTime? customEndDate) {
    final now = DateTime.now();
    if (timeRange == 'custom') {
      return customEndDate ?? now;
    }
    return now;
  }

  Future<void> _pickCustomDate({
    required bool isStart,
    required String section,
  }) async {
    final now = DateTime.now();
    final customStartDate = section == 'category'
        ? (_categoryCustomStartDate ?? now)
        : (_trendCustomStartDate ?? now);
    final customEndDate = section == 'category'
        ? (_categoryCustomEndDate ?? now)
        : (_trendCustomEndDate ?? now);
    final minDate = _accountCreatedAt ?? now;
    final maxDate = isStart
        ? (section == 'category'
              ? (_categoryCustomEndDate ?? now)
              : (_trendCustomEndDate ?? now))
        : now;

    final initialDate = isStart ? customStartDate : customEndDate;
    final firstDate = isStart ? minDate : customStartDate;
    final lastDate = isStart ? maxDate : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) return;

    if (isStart) {
      final endDate = section == 'category'
          ? (_categoryCustomEndDate ?? now)
          : (_trendCustomEndDate ?? now);
      if (picked.isAfter(endDate)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start date cannot be later than the end date.'),
            ),
          );
        }
        return;
      }

      setState(() {
        if (section == 'category') {
          _categoryCustomStartDate = picked;
        } else {
          _trendCustomStartDate = picked;
        }
      });
      return;
    }

    final startDate = section == 'category'
        ? (_categoryCustomStartDate ?? now)
        : (_trendCustomStartDate ?? now);
    if (picked.isBefore(startDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date cannot be earlier than the start date.'),
          ),
        );
      }
      return;
    }

    setState(() {
      if (section == 'category') {
        _categoryCustomEndDate = picked;
      } else {
        _trendCustomEndDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryRangeStart = _rangeStartFor(
      _categoryTimeRange,
      _categoryCustomStartDate,
    );
    final categoryRangeEnd = _rangeEndFor(
      _categoryTimeRange,
      _categoryCustomEndDate,
    );
    final trendRangeStart = _rangeStartFor(
      _trendTimeRange,
      _trendCustomStartDate,
    );
    final trendRangeEnd = _rangeEndFor(_trendTimeRange, _trendCustomEndDate);
    final isCategoryCustomRange = _categoryTimeRange == 'custom';
    final isTrendCustomRange = _trendTimeRange == 'custom';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(AppStrings.analytics),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            AppStrings.categoryBreakdown,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _typeFilterWidget(
            selected: _categoryTypeFilter,
            onChanged: (value) => setState(() => _categoryTypeFilter = value),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _timeChip(
                  label: AppStrings.day,
                  value: 'day',
                  selectedValue: _categoryTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _categoryTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _categoryCustomStartDate = _accountCreatedAt;
                      _categoryCustomEndDate = DateTime.now();
                    });
                  },
                ),
                _timeChip(
                  label: AppStrings.week,
                  value: 'week',
                  selectedValue: _categoryTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _categoryTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _categoryCustomStartDate = _accountCreatedAt;
                      _categoryCustomEndDate = DateTime.now();
                    });
                  },
                ),
                _timeChip(
                  label: AppStrings.month,
                  value: 'month',
                  selectedValue: _categoryTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _categoryTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _categoryCustomStartDate = _accountCreatedAt;
                      _categoryCustomEndDate = DateTime.now();
                    });
                  },
                ),
                _timeChip(
                  label: AppStrings.threeMonths,
                  value: 'quarter',
                  selectedValue: _categoryTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _categoryTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _categoryCustomStartDate = _accountCreatedAt;
                      _categoryCustomEndDate = DateTime.now();
                    });
                  },
                ),
                _timeChip(
                  label: AppStrings.customRange,
                  value: 'custom',
                  selectedValue: _categoryTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _categoryTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _categoryCustomStartDate = _accountCreatedAt;
                      _categoryCustomEndDate = DateTime.now();
                    });
                  },
                ),
              ],
            ),
          ),
          if (isCategoryCustomRange && _initialized) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _pickCustomDate(isStart: true, section: 'category'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_categoryCustomStartDate ?? DateTime.now()).day}/${(_categoryCustomStartDate ?? DateTime.now()).month}/${(_categoryCustomStartDate ?? DateTime.now()).year}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _pickCustomDate(isStart: false, section: 'category'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_categoryCustomEndDate ?? DateTime.now()).day}/${(_categoryCustomEndDate ?? DateTime.now()).month}/${(_categoryCustomEndDate ?? DateTime.now()).year}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ExpensePieChart(
                typeFilter: _categoryTypeFilter,
                rangeStart: categoryRangeStart,
                rangeEnd: categoryRangeEnd,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.spendingTrend,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _typeFilterWidget(
            selected: _trendTypeFilter,
            onChanged: (value) => setState(() => _trendTypeFilter = value),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _timeChip(
                  label: AppStrings.day,
                  value: 'day',
                  selectedValue: _trendTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _trendTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _trendCustomStartDate = _accountCreatedAt;
                      _trendCustomEndDate = DateTime.now();
                    });
                  },
                ),
                _timeChip(
                  label: AppStrings.week,
                  value: 'week',
                  selectedValue: _trendTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _trendTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _trendCustomStartDate = _accountCreatedAt;
                      _trendCustomEndDate = DateTime.now();
                    });
                  },
                ),
                _timeChip(
                  label: AppStrings.month,
                  value: 'month',
                  selectedValue: _trendTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _trendTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _trendCustomStartDate = _accountCreatedAt;
                      _trendCustomEndDate = DateTime.now();
                    });
                  },
                ),
                _timeChip(
                  label: AppStrings.threeMonths,
                  value: 'quarter',
                  selectedValue: _trendTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _trendTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _trendCustomStartDate = _accountCreatedAt;
                      _trendCustomEndDate = DateTime.now();
                    });
                  },
                ),
                _timeChip(
                  label: AppStrings.customRange,
                  value: 'custom',
                  selectedValue: _trendTimeRange,
                  onChanged: (timeRange) {
                    setState(() => _trendTimeRange = timeRange);
                    if (timeRange != 'custom' || !_initialized) return;
                    setState(() {
                      _trendCustomStartDate = _accountCreatedAt;
                      _trendCustomEndDate = DateTime.now();
                    });
                  },
                ),
              ],
            ),
          ),
          if (isTrendCustomRange && _initialized) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _pickCustomDate(isStart: true, section: 'trend'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_trendCustomStartDate ?? DateTime.now()).day}/${(_trendCustomStartDate ?? DateTime.now()).month}/${(_trendCustomStartDate ?? DateTime.now()).year}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _pickCustomDate(isStart: false, section: 'trend'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_trendCustomEndDate ?? DateTime.now()).day}/${(_trendCustomEndDate ?? DateTime.now()).month}/${(_trendCustomEndDate ?? DateTime.now()).year}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SpendingBarChart(
                typeFilter: _trendTypeFilter,
                rangeStart: trendRangeStart,
                rangeEnd: trendRangeEnd,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeFilterWidget({
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return SegmentedButton<String>(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          final colorScheme = Theme.of(context).colorScheme;
          return states.contains(WidgetState.selected)
              ? colorScheme.primaryContainer
              : colorScheme.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          final colorScheme = Theme.of(context).colorScheme;
          return states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      segments: const [
        ButtonSegment(value: 'all', label: Text(AppStrings.viewAll)),
        ButtonSegment(value: 'expense', label: Text(AppStrings.onlyExpense)),
        ButtonSegment(value: 'income', label: Text(AppStrings.onlyIncome)),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }

  Widget _timeChip({
    required String label,
    required String value,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final selected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onChanged(value),
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundColor: Theme.of(context).colorScheme.surface,
        labelStyle: TextStyle(
          color: selected
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurface,
        ),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}
