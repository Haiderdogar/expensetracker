import 'package:flutter/material.dart';

DateTime startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day, 0, 0, 0, 0, 0);
}

DateTime endOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);
}

DateTimeRange analyticsDateRange(
  String timeRange, {
  DateTime? customStartDate,
  DateTime? customEndDate,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();

  switch (timeRange) {
    case 'day':
      return DateTimeRange(
        start: startOfDay(current),
        end: endOfDay(current),
      );

    case 'week':
      // Monday as first day of week: current.weekday gives 1 (Mon) to 7 (Sun)
      final startOfWeek = current.subtract(Duration(days: current.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return DateTimeRange(
        start: startOfDay(startOfWeek),
        end: endOfDay(endOfWeek),
      );

    case 'month':
      final startOfMonth = DateTime(current.year, current.month, 1);
      // Day 0 of next month is the last day of current month (handles leap years & 28/30/31 days safely)
      final endOfMonth = DateTime(current.year, current.month + 1, 0);
      return DateTimeRange(
        start: startOfDay(startOfMonth),
        end: endOfDay(endOfMonth),
      );

    case 'quarter':
      // Current quarter (3 months)
      final quarterStartMonth = ((current.month - 1) ~/ 3) * 3 + 1;
      final startOfQuarter = DateTime(current.year, quarterStartMonth, 1);
      final endOfQuarter = DateTime(current.year, quarterStartMonth + 3, 0);
      return DateTimeRange(
        start: startOfDay(startOfQuarter),
        end: endOfDay(endOfQuarter),
      );

    case 'custom':
      final start = customStartDate ?? current;
      final end = customEndDate ?? current;
      return DateTimeRange(
        start: startOfDay(start.isBefore(end) ? start : end),
        end: endOfDay(start.isBefore(end) ? end : start),
      );

    default:
      final startOfMonth = DateTime(current.year, current.month, 1);
      final endOfMonth = DateTime(current.year, current.month + 1, 0);
      return DateTimeRange(
        start: startOfDay(startOfMonth),
        end: endOfDay(endOfMonth),
      );
  }
}
