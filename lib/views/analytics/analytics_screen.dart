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
  String _typeFilter = 'all';
  String _timeRange = 'week';
  late DateTime _customStartDate;
  late DateTime _customEndDate;
  late DateTime _accountCreatedAt;
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
      _customStartDate = createdAt;
      _customEndDate = now;
      _initialized = true;
    });
  }

  DateTime get _rangeStart {
    final now = DateTime.now();
    switch (_timeRange) {
      case 'day':
        return now.subtract(const Duration(days: 1));
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month - 1, now.day);
      case 'quarter':
        return DateTime(now.year, now.month - 3, now.day);
      case 'custom':
        return _customStartDate;
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  DateTime get _rangeEnd {
    final now = DateTime.now();
    if (_timeRange == 'custom') {
      return _customEndDate;
    }
    return now;
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? _customStartDate : _customEndDate;
    final firstDate = isStart ? _accountCreatedAt : _customStartDate;
    final lastDate = isStart ? _customEndDate : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) return;

    if (isStart) {
      if (picked.isAfter(_customEndDate)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start date cannot be later than the end date.'),
            ),
          );
        }
        return;
      }
      setState(() => _customStartDate = picked);
      return;
    }

    if (picked.isBefore(_customStartDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date cannot be earlier than the start date.'),
          ),
        );
      }
      return;
    }

    setState(() => _customEndDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isCustomRange = _timeRange == 'custom';

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
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text(AppStrings.viewAll)),
              ButtonSegment(
                value: 'expense',
                label: Text(AppStrings.onlyExpense),
              ),
              ButtonSegment(
                value: 'income',
                label: Text(AppStrings.onlyIncome),
              ),
            ],
            selected: {_typeFilter},
            onSelectionChanged: (selection) {
              setState(() => _typeFilter = selection.first);
            },
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _timeChip(label: AppStrings.day, value: 'day'),
                _timeChip(label: AppStrings.week, value: 'week'),
                _timeChip(label: AppStrings.month, value: 'month'),
                _timeChip(label: AppStrings.threeMonths, value: 'quarter'),
                _timeChip(label: AppStrings.customRange, value: 'custom'),
              ],
            ),
          ),
          if (isCustomRange && _initialized) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickCustomDate(isStart: true),
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
                            '${_customStartDate.day}/${_customStartDate.month}/${_customStartDate.year}',
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
                    onTap: () => _pickCustomDate(isStart: false),
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
                            '${_customEndDate.day}/${_customEndDate.month}/${_customEndDate.year}',
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
                typeFilter: _typeFilter,
                rangeStart: _rangeStart,
                rangeEnd: _rangeEnd,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.spendingTrend,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SpendingBarChart(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeChip({required String label, required String value}) {
    final selected = _timeRange == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _timeRange = value);
          if (value != 'custom' || !_initialized) return;
          setState(() {
            _customStartDate = _accountCreatedAt;
            _customEndDate = DateTime.now();
          });
        },
      ),
    );
  }
}
