import 'package:intl/intl.dart';

abstract final class Formatters {
  static String currency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  static String date(DateTime date) => DateFormat.yMMMd().format(date);

  static String dateTime(DateTime date) => DateFormat.yMMMd().add_jm().format(date);

  static String monthYear(DateTime date) => DateFormat('yyyy-MM').format(date);

  static String monthYearLabel(DateTime date) => DateFormat.yMMMM().format(date);

  static String isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Returns ISO 8601 datetime string combining the provided date (year,month,day)
  /// with the current system time (hour,min,sec). Used to save the time when a
  /// transaction is created.
  static String isoDateTimeWithCurrentTime(DateTime date) {
    final now = DateTime.now();
    final combined = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
    return combined.toIso8601String();
  }

  static DateTime parseIsoDate(String value) => DateTime.parse(value);
}
