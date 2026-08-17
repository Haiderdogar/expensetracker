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

  static DateTime parseIsoDate(String value) => DateTime.parse(value);
}
