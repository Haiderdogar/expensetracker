import 'package:expensetracker/views/analytics/analytics_date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Analytics Date Range Calculations', () {
    test('day range starts at 00:00:00 and ends at 23:59:59', () {
      final fixedDate = DateTime(2025, 6, 15, 14, 30, 45);
      final range = analyticsDateRange('day', now: fixedDate);

      expect(range.start, DateTime(2025, 6, 15, 0, 0, 0));
      expect(range.end.year, 2025);
      expect(range.end.month, 6);
      expect(range.end.day, 15);
      expect(range.end.hour, 23);
      expect(range.end.minute, 59);
      expect(range.end.second, 59);
    });

    test('week range starts on Monday and ends on Sunday', () {
      // 2025-06-18 is Wednesday (weekday 3)
      final wednesday = DateTime(2025, 6, 18, 12, 0);
      final range = analyticsDateRange('week', now: wednesday);

      // Monday is 2025-06-16
      expect(range.start, DateTime(2025, 6, 16, 0, 0, 0));
      // Sunday is 2025-06-22
      expect(range.end.year, 2025);
      expect(range.end.month, 6);
      expect(range.end.day, 22);
      expect(range.end.hour, 23);
    });

    test('month range handles 31-day month without overflow', () {
      // March 31 - previously would overflow when subtracting month with day 31
      final march31 = DateTime(2025, 3, 31, 22, 10);
      final range = analyticsDateRange('month', now: march31);

      expect(range.start, DateTime(2025, 3, 1, 0, 0, 0));
      expect(range.end.year, 2025);
      expect(range.end.month, 3);
      expect(range.end.day, 31);
      expect(range.end.hour, 23);
      expect(range.end.minute, 59);
    });

    test('month range handles leap year February accurately', () {
      final leapFeb = DateTime(2024, 2, 14);
      final range = analyticsDateRange('month', now: leapFeb);

      expect(range.start, DateTime(2024, 2, 1, 0, 0, 0));
      expect(range.end.year, 2024);
      expect(range.end.month, 2);
      expect(range.end.day, 29); // 2024 is a leap year
    });

    test('month range handles non-leap year February accurately', () {
      final nonLeapFeb = DateTime(2025, 2, 14);
      final range = analyticsDateRange('month', now: nonLeapFeb);

      expect(range.start, DateTime(2025, 2, 1, 0, 0, 0));
      expect(range.end.year, 2025);
      expect(range.end.month, 2);
      expect(range.end.day, 28);
    });

    test('quarter range correctly covers 3-month quarter', () {
      // November 15 (Q4: Oct, Nov, Dec)
      final nov15 = DateTime(2025, 11, 15);
      final range = analyticsDateRange('quarter', now: nov15);

      expect(range.start, DateTime(2025, 10, 1, 0, 0, 0));
      expect(range.end.year, 2025);
      expect(range.end.month, 12);
      expect(range.end.day, 31);
    });

    test('custom range normalizes start and end times and handles reverse ordering', () {
      final start = DateTime(2025, 5, 20, 15, 30);
      final end = DateTime(2025, 5, 10, 8, 0); // end is earlier than start

      final range = analyticsDateRange(
        'custom',
        customStartDate: start,
        customEndDate: end,
      );

      expect(range.start, DateTime(2025, 5, 10, 0, 0, 0));
      expect(range.end.year, 2025);
      expect(range.end.month, 5);
      expect(range.end.day, 20);
      expect(range.end.hour, 23);
      expect(range.end.minute, 59);
    });
  });
}
