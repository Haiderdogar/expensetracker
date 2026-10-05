import 'package:expensetracker/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.dashboardCurrency', () {
    test('shows zero with two decimal places', () {
      expect(Formatters.dashboardCurrency(0), r'$0.00');
    });

    test('omits decimals for whole amounts', () {
      expect(Formatters.dashboardCurrency(100), r'$100');
    });

    test('shows decimals for fractional amounts', () {
      expect(Formatters.dashboardCurrency(100.5), r'$100.50');
    });
  });

  group('Formatters.amountInput', () {
    test('omits decimals for whole amounts', () {
      expect(Formatters.amountInput(100), '100');
    });

    test('shows two decimal places for fractional amounts', () {
      expect(Formatters.amountInput(100.5), '100.50');
    });
  });
}
