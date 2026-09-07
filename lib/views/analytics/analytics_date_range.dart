DateTime analyticsRangeStart(String timeRange, DateTime? customStartDate) {
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

DateTime analyticsRangeEnd(String timeRange, DateTime? customEndDate) {
  return timeRange == 'custom' ? customEndDate ?? DateTime.now() : DateTime.now();
}
