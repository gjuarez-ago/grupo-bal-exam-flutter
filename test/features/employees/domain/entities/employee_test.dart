import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entryDate = DateTime(2020, 3, 15);
  final birthDate = DateTime(1990, 7, 1);

  Employee buildEmployee({bool isActive = true}) => Employee(
    id: 'emp-1',
    fullName: 'Ana López',
    area: 'Tecnología',
    position: 'Desarrolladora',
    gender: Gender.female,
    entryDate: entryDate,
    birthDate: birthDate,
    isActive: isActive,
  );

  group('Employee', () {
    test('conserva los valores con los que se construye', () {
      final employee = buildEmployee();

      expect(employee.id, 'emp-1');
      expect(employee.fullName, 'Ana López');
      expect(employee.area, 'Tecnología');
      expect(employee.position, 'Desarrolladora');
      expect(employee.gender, Gender.female);
      expect(employee.entryDate, entryDate);
      expect(employee.birthDate, birthDate);
      expect(employee.isActive, isTrue);
    });

    test('dos empleados con los mismos valores son iguales', () {
      expect(buildEmployee(), buildEmployee());
    });

    test('empleados con distinto estado activo no son iguales', () {
      expect(buildEmployee(), isNot(buildEmployee(isActive: false)));
    });

    test('copyWith reemplaza solo los campos indicados y conserva el id', () {
      final employee = buildEmployee();

      final updated = employee.copyWith(isActive: false);

      expect(updated, buildEmployee(isActive: false));
      expect(updated.id, employee.id);
      expect(employee.isActive, isTrue);
    });
  });
}
