import 'package:employee_management/features/employees/data/datasources/employee_local_data_source.dart';
import 'package:employee_management/features/employees/data/datasources/employee_mock_data.dart';
import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EmployeeLocalDataSource dataSource;

  setUp(() {
    dataSource = EmployeeLocalDataSource();
  });

  Employee addSampleEmployee() => dataSource.addEmployee(
    fullName: 'Luis Ramírez',
    area: 'Tecnología',
    position: 'QA',
    gender: Gender.male,
    entryDate: DateTime(2024, 1, 10),
    birthDate: DateTime(1995, 5, 20),
  );

  group('EmployeeLocalDataSource', () {
    test('los datos ficticios tienen entre 4 y 6 empleados con id único', () {
      final ids = employeeMockData.map((employee) => employee.id).toSet();

      expect(employeeMockData.length, inInclusiveRange(4, 6));
      expect(ids.length, employeeMockData.length);
    });

    test('devuelve los empleados ficticios por defecto', () {
      expect(dataSource.getEmployees(), employeeMockData);
    });

    test('admite iniciar con una lista vacía', () {
      final empty = EmployeeLocalDataSource(initialEmployees: []);

      expect(empty.getEmployees(), isEmpty);
    });

    test('la lista devuelta no se puede modificar', () {
      final employees = dataSource.getEmployees();

      expect(() => employees.clear(), throwsUnsupportedError);
      expect(dataSource.getEmployees(), employeeMockData);
    });

    test('agregar un empleado le asigna un id único y lo registra activo', () {
      final employee = addSampleEmployee();
      final employees = dataSource.getEmployees();

      expect(employee.isActive, isTrue);
      expect(employees.last, employee);
      expect(employees.length, employeeMockData.length + 1);
      expect(employees.map((e) => e.id).toSet().length, employees.length);
    });

    test('registros sucesivos reciben identificadores distintos', () {
      final first = addSampleEmployee();
      final second = addSampleEmployee();

      expect(first.id, isNot(second.id));
    });

    test('actualizar el estado modifica solo el empleado indicado', () {
      final before = dataSource.getEmployees();

      final updated = dataSource.updateEmployeeStatus(
        id: 'emp-2',
        isActive: false,
      );
      final after = dataSource.getEmployees();

      expect(updated.id, 'emp-2');
      expect(updated.isActive, isFalse);
      expect(after.length, before.length);
      for (var i = 0; i < before.length; i++) {
        if (before[i].id == 'emp-2') {
          expect(after[i], before[i].copyWith(isActive: false));
        } else {
          expect(after[i], before[i]);
        }
      }
    });

    test('un id inexistente lanza EmployeeNotFoundException', () {
      expect(
        () => dataSource.updateEmployeeStatus(id: 'no-existe', isActive: true),
        throwsA(isA<EmployeeNotFoundException>()),
      );
      expect(dataSource.getEmployees(), employeeMockData);
    });
  });
}
