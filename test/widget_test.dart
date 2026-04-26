import 'package:flutter_test/flutter_test.dart';
import 'package:red_shop/utils/formatters.dart';

void main() {
  test('formatCurrency adds separators and decimals', () {
    expect(formatCurrency(1234.5), 'ETB 1,234.50');
    expect(formatCurrency(-75), '-ETB 75.00');
  });
}
