import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/presentation/cubit/employee_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Employee buildEmployee(String id, {required bool isActive}) => Employee(
    id: id,
    fullName: 'Empleado $id',
    area: 'Área',
    position: 'Puesto',
    gender: Gender.female,
    entryDate: DateTime(2020, 1, 1),
    birthDate: DateTime(1990, 1, 1),
    isActive: isActive,
  );

  group('EmployeeState contadores', () {
    test('sin empleados todos los totales son cero', () {
      const state = EmployeeState();

      expect(state.totalCount, 0);
      expect(state.activeCount, 0);
      expect(state.inactiveCount, 0);
    });

    test('cuenta activos e inactivos según el estado de cada empleado', () {
      final state = EmployeeState(
        status: EmployeeStatus.success,
        employees: [
          buildEmployee('a', isActive: true),
          buildEmployee('b', isActive: false),
          buildEmployee('c', isActive: true),
        ],
      );

      expect(state.totalCount, 3);
      expect(state.activeCount, 2);
      expect(state.inactiveCount, 1);
    });
  });
}
