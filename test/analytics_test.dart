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

    test('week range covers today and the previous six days', () {
      final current = DateTime(2025, 6, 18, 12, 0);
      final range = analyticsDateRange('week', now: current);

      expect(range.start, DateTime(2025, 6, 12, 0, 0));
      expect(range.end, DateTime(2025, 6, 18, 23, 59, 59, 999, 999));
    });

    test('month range covers today and the previous 29 days', () {
      final current = DateTime(2025, 3, 31, 22, 10);
      final range = analyticsDateRange('month', now: current);

      expect(range.start, DateTime(2025, 3, 2, 0, 0));
      expect(range.end, DateTime(2025, 3, 31, 23, 59, 59, 999, 999));
    });

    test('three-month range covers today and the previous 89 days', () {
      final current = DateTime(2025, 3, 31, 22, 10);
      final range = analyticsDateRange('quarter', now: current);

      expect(range.start, DateTime(2025, 1, 1, 0, 0));
      expect(range.end, DateTime(2025, 3, 31, 23, 59, 59, 999, 999));
    });

    test(
      'custom range normalizes start and end times and handles reverse ordering',
      () {
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
        expect(range.end.second, 59);
        expect(range.end.millisecond, 999);
        expect(range.end.microsecond, 999);
      },
    );
  });
}
