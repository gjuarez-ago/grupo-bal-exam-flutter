import 'package:employee_management/features/employees/data/datasources/employee_mock_data.dart';
import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/domain/entities/employee_areas.dart';
import 'package:employee_management/features/employees/presentation/validators/employee_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 27, 15, 30);

  group('EmployeeFormValidators — textos obligatorios', () {
    test('el nombre vacío o con solo espacios es inválido', () {
      expect(EmployeeFormValidators.fullName(null), isNotNull);
      expect(EmployeeFormValidators.fullName(''), isNotNull);
      expect(EmployeeFormValidators.fullName('   '), isNotNull);
    });

    test('acepta nombres con acentos, guiones y apóstrofos', () {
      expect(EmployeeFormValidators.fullName('José María Núñez'), isNull);
      expect(EmployeeFormValidators.fullName("Ana-Lucía O'Connor"), isNull);
    });

    test('el puesto vacío o con solo espacios es inválido', () {
      expect(EmployeeFormValidators.position(''), isNotNull);
      expect(EmployeeFormValidators.position('  '), isNotNull);
      expect(EmployeeFormValidators.position('Analista'), isNull);
    });
  });

  group('EmployeeFormValidators — selecciones', () {
    test('área y género son obligatorios', () {
      expect(EmployeeFormValidators.area(null), 'Selecciona un área.');
      expect(EmployeeFormValidators.area('Ventas'), isNull);
      expect(EmployeeFormValidators.gender(null), 'Selecciona un género.');
      expect(EmployeeFormValidators.gender(Gender.male), isNull);
    });

    test('el catálogo de áreas contiene las áreas de los datos ficticios', () {
      for (final employee in employeeMockData) {
        expect(employeeAreas, contains(employee.area));
      }
    });
  });

  group('EmployeeFormValidators — fecha de ingreso', () {
    test('es obligatoria', () {
      expect(
        EmployeeFormValidators.entryDate(null, today: today),
        'Selecciona la fecha de ingreso.',
      );
    });

    test('hoy y fechas pasadas son válidas', () {
      expect(EmployeeFormValidators.entryDate(today, today: today), isNull);
      expect(
        EmployeeFormValidators.entryDate(DateTime(2020, 1, 1), today: today),
        isNull,
      );
    });

    test('una fecha futura es rechazada', () {
      expect(
        EmployeeFormValidators.entryDate(DateTime(2026, 10, 28), today: today),
        'La fecha de ingreso no puede ser futura.',
      );
    });
  });

  group('EmployeeFormValidators — fecha de nacimiento', () {
    test('es obligatoria', () {
      expect(
        EmployeeFormValidators.birthDate(null, today: today),
        'Selecciona la fecha de nacimiento.',
      );
    });

    test('una fecha futura o igual a hoy es rechazada', () {
      const message = 'La fecha de nacimiento debe ser anterior a hoy.';
      expect(
        EmployeeFormValidators.birthDate(DateTime(2027, 1, 1), today: today),
        message,
      );
      expect(
        EmployeeFormValidators.birthDate(DateTime(2026, 10, 27), today: today),
        message,
      );
    });

    test('debe ser anterior a la fecha de ingreso', () {
      const message =
          'La fecha de nacimiento debe ser anterior a la fecha de ingreso.';
      expect(
        EmployeeFormValidators.birthDate(
          DateTime(2021, 5, 1),
          today: today,
          entryDate: DateTime(2020, 1, 1),
        ),
        message,
      );
      expect(
        EmployeeFormValidators.birthDate(
          DateTime(2020, 1, 1),
          today: today,
          entryDate: DateTime(2020, 1, 1),
        ),
        message,
      );
    });

    test('una fecha coherente es válida y no exige edad mínima', () {
      expect(
        EmployeeFormValidators.birthDate(
          DateTime(1995, 5, 20),
          today: today,
          entryDate: DateTime(2024, 1, 10),
        ),
        isNull,
      );
      expect(
        EmployeeFormValidators.birthDate(
          DateTime(2026, 10, 1),
          today: today,
          entryDate: DateTime(2026, 10, 2),
        ),
        isNull,
      );
    });
  });
}
