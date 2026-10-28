import 'package:employee_management/features/employees/data/datasources/employee_local_data_source.dart';
import 'package:employee_management/features/employees/data/datasources/employee_mock_data.dart';
import 'package:employee_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EmployeeRepository repository;

  setUp(() {
    repository = EmployeeRepositoryImpl(EmployeeLocalDataSource());
  });

  group('EmployeeRepositoryImpl', () {
    test('obtiene los empleados de la fuente local', () async {
      expect(await repository.getEmployees(), employeeMockData);
    });

    test('devuelve una lista vacía si no hay empleados', () async {
      final emptyRepository = EmployeeRepositoryImpl(
        EmployeeLocalDataSource(initialEmployees: []),
      );

      expect(await emptyRepository.getEmployees(), isEmpty);
    });

    test(
      'registra un empleado y lo incluye en consultas posteriores',
      () async {
        final registered = await repository.registerEmployee(
          fullName: 'Luis Ramírez',
          area: 'Tecnología',
          position: 'QA',
          gender: Gender.male,
          entryDate: DateTime(2024, 1, 10),
          birthDate: DateTime(1995, 5, 20),
        );

        final employees = await repository.getEmployees();

        expect(registered.fullName, 'Luis Ramírez');
        expect(registered.isActive, isTrue);
        expect(employees, [...employeeMockData, registered]);
      },
    );

    test('actualiza el estado y conserva a los demás empleados', () async {
      final updated = await repository.updateEmployeeStatus(
        id: 'emp-1',
        isActive: false,
      );

      final employees = await repository.getEmployees();

      expect(updated, employeeMockData.first.copyWith(isActive: false));
      expect(employees, [updated, ...employeeMockData.skip(1)]);
    });

    test('propaga EmployeeNotFoundException para un id inexistente', () {
      expect(
        repository.updateEmployeeStatus(id: 'no-existe', isActive: false),
        throwsA(isA<EmployeeNotFoundException>()),
      );
    });
  });
}
