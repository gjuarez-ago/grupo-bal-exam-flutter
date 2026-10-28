import 'package:employee_management/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDate', () {
    test('formatea como dd/MM/yyyy', () {
      expect(formatDate(DateTime(2026, 10, 27)), '27/10/2026');
    });

    test('rellena con cero el día y el mes de un dígito', () {
      expect(formatDate(DateTime(2021, 2, 5)), '05/02/2021');
    });

    test('ignora la hora', () {
      expect(formatDate(DateTime(2023, 12, 31, 23, 59)), '31/12/2023');
    });
  });
}
