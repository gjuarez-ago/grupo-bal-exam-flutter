import 'package:bloc_test/bloc_test.dart';
import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:employee_management/features/employees/presentation/cubit/employee_cubit.dart';
import 'package:employee_management/features/employees/presentation/cubit/employee_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmployeeRepository extends Mock implements EmployeeRepository {}

void main() {
  late MockEmployeeRepository repository;

  final employees = [
    Employee(
      id: 'emp-1',
      fullName: 'Ana López',
      area: 'Tecnología',
      position: 'Desarrolladora',
      gender: Gender.female,
      entryDate: DateTime(2020, 3, 15),
      birthDate: DateTime(1990, 7, 1),
      isActive: true,
    ),
    Employee(
      id: 'emp-2',
      fullName: 'Carlos Pérez',
      area: 'Finanzas',
      position: 'Analista',
      gender: Gender.male,
      entryDate: DateTime(2018, 1, 8),
      birthDate: DateTime(1985, 11, 23),
      isActive: false,
    ),
  ];

  setUp(() {
    repository = MockEmployeeRepository();
  });

  group('EmployeeCubit', () {
    test('el estado inicial es EmployeeStatus.initial sin empleados', () {
      final cubit = EmployeeCubit(repository);

      expect(cubit.state, const EmployeeState());
      expect(cubit.state.status, EmployeeStatus.initial);
      expect(cubit.state.employees, isEmpty);
      expect(cubit.state.errorMessage, isNull);

      cubit.close();
    });

    blocTest<EmployeeCubit, EmployeeState>(
      'emite carga y éxito con los empleados del repositorio',
      setUp: () {
        when(
          () => repository.getEmployees(),
        ).thenAnswer((_) async => employees);
      },
      build: () => EmployeeCubit(repository),
      act: (cubit) => cubit.loadEmployees(),
      expect: () => [
        const EmployeeState(status: EmployeeStatus.loading),
        EmployeeState(status: EmployeeStatus.success, employees: employees),
      ],
      verify: (_) => verify(() => repository.getEmployees()).called(1),
    );

    blocTest<EmployeeCubit, EmployeeState>(
      'una lista vacía es un resultado exitoso',
      setUp: () {
        when(() => repository.getEmployees()).thenAnswer((_) async => []);
      },
      build: () => EmployeeCubit(repository),
      act: (cubit) => cubit.loadEmployees(),
      expect: () => const [
        EmployeeState(status: EmployeeStatus.loading),
        EmployeeState(status: EmployeeStatus.success),
      ],
    );

    blocTest<EmployeeCubit, EmployeeState>(
      'emite fallo con el mensaje de EmployeeRepositoryException',
      setUp: () {
        when(
          () => repository.getEmployees(),
        ).thenThrow(const EmployeeRepositoryException('No hay conexión.'));
      },
      build: () => EmployeeCubit(repository),
      act: (cubit) => cubit.loadEmployees(),
      expect: () => const [
        EmployeeState(status: EmployeeStatus.loading),
        EmployeeState(
          status: EmployeeStatus.failure,
          errorMessage: 'No hay conexión.',
        ),
      ],
    );

    blocTest<EmployeeCubit, EmployeeState>(
      'ante un error inesperado emite fallo genérico y reporta el error',
      setUp: () {
        when(() => repository.getEmployees()).thenThrow(StateError('fallo'));
      },
      build: () => EmployeeCubit(repository),
      act: (cubit) => cubit.loadEmployees(),
      expect: () => const [
        EmployeeState(status: EmployeeStatus.loading),
        EmployeeState(
          status: EmployeeStatus.failure,
          errorMessage: EmployeeCubit.unexpectedErrorMessage,
        ),
      ],
      errors: () => [isA<StateError>()],
    );

    blocTest<EmployeeCubit, EmployeeState>(
      'conserva los empleados durante una recarga y limpia el error previo',
      setUp: () {
        when(
          () => repository.getEmployees(),
        ).thenAnswer((_) async => employees);
      },
      build: () => EmployeeCubit(repository),
      seed: () => EmployeeState(
        status: EmployeeStatus.failure,
        employees: employees,
        errorMessage: 'Error anterior',
      ),
      act: (cubit) => cubit.loadEmployees(),
      expect: () => [
        EmployeeState(status: EmployeeStatus.loading, employees: employees),
        EmployeeState(status: EmployeeStatus.success, employees: employees),
      ],
    );
  });

  group('EmployeeCubit.registerEmployee', () {
    final newEmployee = Employee(
      id: 'emp-3',
      fullName: 'Luis Ramírez',
      area: 'Tecnología',
      position: 'QA',
      gender: Gender.male,
      entryDate: DateTime(2024, 1, 10),
      birthDate: DateTime(1995, 5, 20),
      isActive: true,
    );

    setUpAll(() {
      registerFallbackValue(Gender.male);
      registerFallbackValue(DateTime(2000));
    });

    When<Future<Employee>> whenRegister() => when(
      () => repository.registerEmployee(
        fullName: any(named: 'fullName'),
        area: any(named: 'area'),
        position: any(named: 'position'),
        gender: any(named: 'gender'),
        entryDate: any(named: 'entryDate'),
        birthDate: any(named: 'birthDate'),
      ),
    );

    Future<bool> register(EmployeeCubit cubit) => cubit.registerEmployee(
      fullName: newEmployee.fullName,
      area: newEmployee.area,
      position: newEmployee.position,
      gender: newEmployee.gender,
      entryDate: newEmployee.entryDate,
      birthDate: newEmployee.birthDate,
    );

    blocTest<EmployeeCubit, EmployeeState>(
      'agrega el empleado registrado al final de la lista actual',
      setUp: () => whenRegister().thenAnswer((_) async => newEmployee),
      build: () => EmployeeCubit(repository),
      seed: () =>
          EmployeeState(status: EmployeeStatus.success, employees: employees),
      act: (cubit) async => expect(await register(cubit), isTrue),
      expect: () => [
        EmployeeState(status: EmployeeStatus.loading, employees: employees),
        EmployeeState(
          status: EmployeeStatus.success,
          employees: [...employees, newEmployee],
        ),
      ],
      verify: (_) => verify(
        () => repository.registerEmployee(
          fullName: 'Luis Ramírez',
          area: 'Tecnología',
          position: 'QA',
          gender: Gender.male,
          entryDate: DateTime(2024, 1, 10),
          birthDate: DateTime(1995, 5, 20),
        ),
      ).called(1),
    );

    blocTest<EmployeeCubit, EmployeeState>(
      'si el registro falla emite fallo y conserva la lista',
      setUp: () => whenRegister().thenThrow(
        const EmployeeRepositoryException('No se pudo registrar.'),
      ),
      build: () => EmployeeCubit(repository),
      seed: () =>
          EmployeeState(status: EmployeeStatus.success, employees: employees),
      act: (cubit) async => expect(await register(cubit), isFalse),
      expect: () => [
        EmployeeState(status: EmployeeStatus.loading, employees: employees),
        EmployeeState(
          status: EmployeeStatus.failure,
          employees: employees,
          errorMessage: 'No se pudo registrar.',
        ),
      ],
    );
  });

  group('EmployeeCubit.updateEmployeeStatus', () {
    final deactivated = employees.first.copyWith(isActive: false);

    blocTest<EmployeeCubit, EmployeeState>(
      'reemplaza solo el empleado actualizado y conserva a los demás',
      setUp: () {
        when(
          () => repository.updateEmployeeStatus(id: 'emp-1', isActive: false),
        ).thenAnswer((_) async => deactivated);
      },
      build: () => EmployeeCubit(repository),
      seed: () =>
          EmployeeState(status: EmployeeStatus.success, employees: employees),
      act: (cubit) async => expect(
        await cubit.updateEmployeeStatus(id: 'emp-1', isActive: false),
        isTrue,
      ),
      expect: () => [
        EmployeeState(status: EmployeeStatus.loading, employees: employees),
        EmployeeState(
          status: EmployeeStatus.success,
          employees: [deactivated, employees[1]],
        ),
      ],
    );

    blocTest<EmployeeCubit, EmployeeState>(
      'un id inexistente emite fallo sin modificar la lista',
      setUp: () {
        when(
          () =>
              repository.updateEmployeeStatus(id: 'no-existe', isActive: true),
        ).thenThrow(const EmployeeNotFoundException('no-existe'));
      },
      build: () => EmployeeCubit(repository),
      seed: () =>
          EmployeeState(status: EmployeeStatus.success, employees: employees),
      act: (cubit) async => expect(
        await cubit.updateEmployeeStatus(id: 'no-existe', isActive: true),
        isFalse,
      ),
      expect: () => [
        EmployeeState(status: EmployeeStatus.loading, employees: employees),
        EmployeeState(
          status: EmployeeStatus.failure,
          employees: employees,
          errorMessage: const EmployeeNotFoundException('no-existe').message,
        ),
      ],
    );

    blocTest<EmployeeCubit, EmployeeState>(
      'después de un fallo el Cubit puede seguir operando',
      setUp: () {
        when(
          () =>
              repository.updateEmployeeStatus(id: 'no-existe', isActive: true),
        ).thenThrow(const EmployeeNotFoundException('no-existe'));
        when(
          () => repository.updateEmployeeStatus(id: 'emp-1', isActive: false),
        ).thenAnswer((_) async => deactivated);
      },
      build: () => EmployeeCubit(repository),
      seed: () =>
          EmployeeState(status: EmployeeStatus.success, employees: employees),
      act: (cubit) async {
        await cubit.updateEmployeeStatus(id: 'no-existe', isActive: true);
        await cubit.updateEmployeeStatus(id: 'emp-1', isActive: false);
      },
      skip: 2,
      expect: () => [
        EmployeeState(status: EmployeeStatus.loading, employees: employees),
        EmployeeState(
          status: EmployeeStatus.success,
          employees: [deactivated, employees[1]],
        ),
      ],
    );
  });
}
