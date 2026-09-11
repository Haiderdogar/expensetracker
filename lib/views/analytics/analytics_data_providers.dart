import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/category_utils.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import 'analytics_date_range.dart';
import 'analytics_filters_provider.dart';

final analyticsDateRangeProvider = Provider<DateTimeRange>((ref) {
  final filter = ref.watch(analyticsFilterProvider);
  return analyticsDateRange(
    filter.timeRange,
    customStartDate: filter.customStartDate,
    customEndDate: filter.customEndDate,
  );
});

class CategoryBreakdownItem {
  const CategoryBreakdownItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.count,
    required this.color,
    required this.icon,
  });

  final CategoryModel category;
  final double amount;
  final double percentage;
  final int count;
  final Color color;
  final IconData icon;
}

class CategoryBreakdownData {
  const CategoryBreakdownData({
    required this.items,
    required this.total,
    required this.type,
  });

  final List<CategoryBreakdownItem> items;
  final double total;
  final String type;
}

final categoryBreakdownProvider = Provider<CategoryBreakdownData>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? const [];
  final categories = ref.watch(categoriesProvider).value ?? const [];
  final filter = ref.watch(analyticsFilterProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);

  final categoryMap = {for (final cat in categories) cat.id: cat};
  final targetType = filter.categoryType;

  final filtered = transactions.where((tx) {
    if (tx.type != targetType) return false;
    final txDate = DateTime.tryParse(tx.date);
    if (txDate == null) return false;
    return !txDate.isBefore(dateRange.start) && !txDate.isAfter(dateRange.end);
  }).toList();

  final totals = <String, double>{};
  final counts = <String, int>{};

  for (final tx in filtered) {
    totals[tx.categoryId] = (totals[tx.categoryId] ?? 0.0) + tx.amount;
    counts[tx.categoryId] = (counts[tx.categoryId] ?? 0) + 1;
  }

  final grandTotal = totals.values.fold<double>(0.0, (sum, val) => sum + val);

  final items = totals.entries.map((entry) {
    final catId = entry.key;
    final amount = entry.value;
    final count = counts[catId] ?? 0;
    final percent = grandTotal > 0 ? (amount / grandTotal) * 100 : 0.0;

    final cat = categoryMap[catId] ??
        CategoryModel(
          id: catId,
          name: 'Other',
          type: targetType,
          icon: 'category',
          color: '#94A3B8',
        );

    final color = categoryColorFromHex(cat.color);
    final icon = categoryIconFromName(cat.icon);

    return CategoryBreakdownItem(
      category: cat,
      amount: amount,
      percentage: percent,
      count: count,
      color: color,
      icon: icon,
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  return CategoryBreakdownData(
    items: items,
    total: grandTotal,
    type: targetType,
  );
});

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalExpense,
    required this.totalIncome,
    required this.netSavings,
    required this.savingsRate,
    required this.dailyAverageExpense,
    required this.topExpenseCategory,
    required this.transactionCount,
    required this.dayCount,
  });

  final double totalExpense;
  final double totalIncome;
  final double netSavings;
  final double savingsRate;
  final double dailyAverageExpense;
  final CategoryBreakdownItem? topExpenseCategory;
  final int transactionCount;
  final int dayCount;
}

final analyticsSummaryProvider = Provider<AnalyticsSummary>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? const [];
  final dateRange = ref.watch(analyticsDateRangeProvider);
  final categories = ref.watch(categoriesProvider).value ?? const [];
  final categoryMap = {for (final cat in categories) cat.id: cat};

  double totalExpense = 0.0;
  double totalIncome = 0.0;
  int count = 0;
  final expenseByCategory = <String, double>{};

  for (final tx in transactions) {
    final txDate = DateTime.tryParse(tx.date);
    if (txDate == null) continue;
    if (txDate.isBefore(dateRange.start) || txDate.isAfter(dateRange.end)) {
      continue;
    }

    count++;
    if (tx.isExpense) {
      totalExpense += tx.amount;
      expenseByCategory[tx.categoryId] =
          (expenseByCategory[tx.categoryId] ?? 0.0) + tx.amount;
    } else if (tx.isIncome) {
      totalIncome += tx.amount;
    }
  }

  // Calculate day count
  final days = (dateRange.end.difference(dateRange.start).inHours / 24).ceil();
  final effectiveDays = days <= 0 ? 1 : days;
  final dailyAverage = totalExpense / effectiveDays;

  CategoryBreakdownItem? topCategory;
  if (expenseByCategory.isNotEmpty) {
    final sorted = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntry = sorted.first;
    final cat = categoryMap[topEntry.key] ??
        CategoryModel(
          id: topEntry.key,
          name: 'Other',
          type: 'expense',
          icon: 'category',
          color: '#94A3B8',
        );
    final percent = totalExpense > 0 ? (topEntry.value / totalExpense) * 100 : 0.0;
    topCategory = CategoryBreakdownItem(
      category: cat,
      amount: topEntry.value,
      percentage: percent,
      count: 0,
      color: categoryColorFromHex(cat.color),
      icon: categoryIconFromName(cat.icon),
    );
  }

  final netSavings = totalIncome - totalExpense;
  final savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;

  return AnalyticsSummary(
    totalExpense: totalExpense,
    totalIncome: totalIncome,
    netSavings: netSavings,
    savingsRate: savingsRate,
    dailyAverageExpense: dailyAverage,
    topExpenseCategory: topCategory,
    transactionCount: count,
    dayCount: effectiveDays,
  );
});

class TrendBucket {
  TrendBucket({
    required this.date,
    required this.label,
    required this.tooltipDate,
    this.expense = 0.0,
    this.income = 0.0,
  });

  final DateTime date;
  final String label;
  final String tooltipDate;
  double expense;
  double income;
}

final trendSeriesProvider = Provider<List<TrendBucket>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? const [];
  final dateRange = ref.watch(analyticsDateRangeProvider);

  final diffDays = dateRange.end.difference(dateRange.start).inDays;

  // 1. Daily intervals for ranges up to 35 days (e.g. week, month)
  if (diffDays <= 35) {
    final buckets = <String, TrendBucket>{};
    var current = DateTime(
      dateRange.start.year,
      dateRange.start.month,
      dateRange.start.day,
    );
    final endDay = DateTime(
      dateRange.end.year,
      dateRange.end.month,
      dateRange.end.day,
    );

    while (!current.isAfter(endDay)) {
      final key = DateFormat('yyyy-MM-dd').format(current);
      final label = diffDays <= 7
          ? DateFormat('E').format(current) // Mon, Tue, etc.
          : '${current.day}'; // 1, 2, 3...
      final tooltip = DateFormat('EEE, d MMM y').format(current);

      buckets[key] = TrendBucket(
        date: current,
        label: label,
        tooltipDate: tooltip,
      );
      current = current.add(const Duration(days: 1));
    }

    for (final tx in transactions) {
      final txDate = DateTime.tryParse(tx.date);
      if (txDate == null) continue;
      if (txDate.isBefore(dateRange.start) || txDate.isAfter(dateRange.end)) {
        continue;
      }
      final key = DateFormat('yyyy-MM-dd').format(txDate);
      final bucket = buckets[key];
      if (bucket != null) {
        if (tx.isExpense) bucket.expense += tx.amount;
        if (tx.isIncome) bucket.income += tx.amount;
      }
    }

    return buckets.values.toList();
  }

  // 2. Monthly intervals for quarter / year / wide custom ranges
  final buckets = <String, TrendBucket>{};
  var currentMonth = DateTime(dateRange.start.year, dateRange.start.month, 1);
  final endMonth = DateTime(dateRange.end.year, dateRange.end.month, 1);

  while (!currentMonth.isAfter(endMonth)) {
    final key = DateFormat('yyyy-MM').format(currentMonth);
    final label = DateFormat('MMM').format(currentMonth);
    final tooltip = DateFormat('MMMM y').format(currentMonth);

    buckets[key] = TrendBucket(
      date: currentMonth,
      label: label,
      tooltipDate: tooltip,
    );
    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
  }

  for (final tx in transactions) {
    final txDate = DateTime.tryParse(tx.date);
    if (txDate == null) continue;
    if (txDate.isBefore(dateRange.start) || txDate.isAfter(dateRange.end)) {
      continue;
    }
    final key = DateFormat('yyyy-MM').format(txDate);
    final bucket = buckets[key];
    if (bucket != null) {
      if (tx.isExpense) bucket.expense += tx.amount;
      if (tx.isIncome) bucket.income += tx.amount;
    }
  }

  return buckets.values.toList();
});
