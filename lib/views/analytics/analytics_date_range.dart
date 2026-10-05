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
      return DateTimeRange(
        start: startOfDay(current.subtract(const Duration(days: 6))),
        end: endOfDay(current),
      );

    case 'month':
      return DateTimeRange(
        start: startOfDay(current.subtract(const Duration(days: 29))),
        end: endOfDay(current),
      );

    case 'quarter':
      return DateTimeRange(
        start: startOfDay(current.subtract(const Duration(days: 89))),
        end: endOfDay(current),
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
