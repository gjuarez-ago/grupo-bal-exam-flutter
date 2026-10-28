import 'package:bloc_test/bloc_test.dart';
import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:employee_management/features/employees/presentation/cubit/employee_cubit.dart';
import 'package:employee_management/features/employees/presentation/cubit/employee_state.dart';
import 'package:employee_management/features/employees/presentation/pages/employees_page.dart';
import 'package:employee_management/features/employees/presentation/widgets/employee_card.dart';
import 'package:employee_management/features/employees/presentation/widgets/employee_list_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmployeeCubit extends MockCubit<EmployeeState>
    implements EmployeeCubit {}

class MockEmployeeRepository extends Mock implements EmployeeRepository {}

final employees = [
  Employee(
    id: 'emp-1',
    fullName: 'Ana Sofía López Ramírez',
    area: 'Tecnología',
    position: 'Desarrolladora Flutter',
    gender: Gender.female,
    entryDate: DateTime(2021, 2, 15),
    birthDate: DateTime(1993, 6, 4),
    isActive: true,
  ),
  Employee(
    id: 'emp-2',
    fullName: 'Carlos Alberto Pérez Núñez',
    area: 'Finanzas',
    position: 'Analista financiero',
    gender: Gender.male,
    entryDate: DateTime(2018, 9, 3),
    birthDate: DateTime(1987, 11, 23),
    isActive: true,
  ),
  Employee(
    id: 'emp-3',
    fullName: 'María Fernanda Torres Gil',
    area: 'Recursos Humanos',
    position: 'Coordinadora de talento',
    gender: Gender.female,
    entryDate: DateTime(2016, 1, 11),
    birthDate: DateTime(1985, 3, 30),
    isActive: false,
  ),
];

/// Pantalla de móvil alta para que todas las tarjetas se construyan.
void useTallPhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 4500);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> pumpPage(WidgetTester tester, EmployeeCubit cubit) {
  useTallPhoneScreen(tester);
  return tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<EmployeeCubit>.value(
        value: cubit,
        child: const EmployeesPage(),
      ),
    ),
  );
}

Finder inCard(String employeeId, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(employeeId)), matching: matching);

bool switchValue(WidgetTester tester, String employeeId) => tester
    .widget<Switch>(
      find.descendant(
        of: find.byKey(EmployeeCard.statusSwitchKey(employeeId)),
        matching: find.byType(Switch),
      ),
    )
    .value;

void expectSummary({
  required int total,
  required int active,
  required int inactive,
}) {
  Finder value(Key key, int count) =>
      find.descendant(of: find.byKey(key), matching: find.text('$count'));

  expect(value(EmployeeListSummary.totalKey, total), findsOneWidget);
  expect(value(EmployeeListSummary.activeKey, active), findsOneWidget);
  expect(value(EmployeeListSummary.inactiveKey, inactive), findsOneWidget);
}

void main() {
  group('EmployeesPage — presentación', () {
    late MockEmployeeCubit cubit;

    setUp(() {
      cubit = MockEmployeeCubit();
    });

    void givenState(EmployeeState state) {
      whenListen(
        cubit,
        const Stream<EmployeeState>.empty(),
        initialState: state,
      );
    }

    testWidgets('muestra el título y el subtítulo', (tester) async {
      givenState(const EmployeeState(status: EmployeeStatus.loading));

      await pumpPage(tester, cubit);

      expect(find.text('Empleados'), findsOneWidget);
      expect(find.text('Consulta y administra tu equipo'), findsOneWidget);
    });

    testWidgets('durante la carga muestra un indicador y ningún empleado', (
      tester,
    ) async {
      givenState(const EmployeeState(status: EmployeeStatus.loading));

      await pumpPage(tester, cubit);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(EmployeeCard), findsNothing);
      expect(find.text(EmployeesPage.emptyMessage), findsNothing);
    });

    testWidgets('antes de cargar también muestra el indicador', (tester) async {
      givenState(const EmployeeState());

      await pumpPage(tester, cubit);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra los datos de cada empleado', (tester) async {
      givenState(
        EmployeeState(status: EmployeeStatus.success, employees: employees),
      );

      await pumpPage(tester, cubit);

      expect(find.byType(EmployeeCard), findsNWidgets(3));
      expect(
        inCard('emp-1', find.text('Ana Sofía López Ramírez')),
        findsOneWidget,
      );
      expect(inCard('emp-1', find.text('Tecnología')), findsOneWidget);
      expect(
        inCard('emp-1', find.text('Desarrolladora Flutter')),
        findsOneWidget,
      );
      expect(inCard('emp-1', find.text('Femenino')), findsOneWidget);
      expect(inCard('emp-1', find.text('Ingreso: 15/02/2021')), findsOneWidget);
      expect(inCard('emp-2', find.text('Masculino')), findsOneWidget);
      expect(inCard('emp-2', find.text('Ingreso: 03/09/2018')), findsOneWidget);
    });

    testWidgets('el estado se muestra con texto y en el interruptor', (
      tester,
    ) async {
      givenState(
        EmployeeState(status: EmployeeStatus.success, employees: employees),
      );

      await pumpPage(tester, cubit);

      expect(inCard('emp-1', find.text('Activo')), findsOneWidget);
      expect(inCard('emp-3', find.text('Inactivo')), findsOneWidget);
      expect(switchValue(tester, 'emp-1'), isTrue);
      expect(switchValue(tester, 'emp-3'), isFalse);
    });

    testWidgets('los contadores coinciden con la lista', (tester) async {
      givenState(
        EmployeeState(status: EmployeeStatus.success, employees: employees),
      );

      await pumpPage(tester, cubit);

      expectSummary(total: 3, active: 2, inactive: 1);
    });

    testWidgets('una lista vacía muestra el mensaje y no el error', (
      tester,
    ) async {
      givenState(const EmployeeState(status: EmployeeStatus.success));

      await pumpPage(tester, cubit);

      expect(find.text(EmployeesPage.emptyMessage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(EmployeesPage.loadErrorTitle), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      // La acción útil del estado vacío es el botón de registro.
      expect(find.text(EmployeesPage.emptyHint), findsOneWidget);
      expect(find.text('Nuevo empleado'), findsOneWidget);
    });

    testWidgets('un error de carga muestra el mensaje y permite reintentar', (
      tester,
    ) async {
      givenState(
        const EmployeeState(
          status: EmployeeStatus.failure,
          errorMessage: 'Sin conexión.',
        ),
      );
      when(() => cubit.loadEmployees()).thenAnswer((_) async {});

      await pumpPage(tester, cubit);

      expect(find.text(EmployeesPage.loadErrorTitle), findsOneWidget);
      expect(find.text('Sin conexión.'), findsOneWidget);
      expect(find.text(EmployeesPage.emptyMessage), findsNothing);

      await tester.tap(find.text('Reintentar'));

      verify(() => cubit.loadEmployees()).called(1);
    });

    testWidgets('el interruptor invoca la operación del Cubit', (tester) async {
      givenState(
        EmployeeState(status: EmployeeStatus.success, employees: employees),
      );
      when(
        () => cubit.updateEmployeeStatus(id: 'emp-2', isActive: false),
      ).thenAnswer((_) async => true);

      await pumpPage(tester, cubit);
      await tester.tap(inCard('emp-2', find.byType(Switch)));

      verify(
        () => cubit.updateEmployeeStatus(id: 'emp-2', isActive: false),
      ).called(1);
    });

    testWidgets('en un móvil pequeño con nombres largos no hay desbordes', (
      tester,
    ) async {
      final longNamed = [
        employees.first.copyWith(
          fullName: 'María de los Ángeles Guadalupe Fernández de la Garza',
          position: 'Coordinadora de proyectos estratégicos regionales',
        ),
        ...employees.skip(1),
      ];
      givenState(
        EmployeeState(status: EmployeeStatus.success, employees: longNamed),
      );

      await pumpPage(tester, cubit);
      tester.view.physicalSize = const Size(960, 1704);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('con una operación en curso los interruptores no responden', (
      tester,
    ) async {
      givenState(
        EmployeeState(status: EmployeeStatus.loading, employees: employees),
      );

      await pumpPage(tester, cubit);
      await tester.tap(inCard('emp-1', find.byType(Switch)));

      verifyNever(
        () => cubit.updateEmployeeStatus(
          id: any(named: 'id'),
          isActive: any(named: 'isActive'),
        ),
      );
    });
  });

  group('EmployeesPage — interacción con el Cubit real', () {
    late MockEmployeeRepository repository;
    late EmployeeCubit cubit;

    setUp(() async {
      repository = MockEmployeeRepository();
      when(() => repository.getEmployees()).thenAnswer((_) async => employees);
      cubit = EmployeeCubit(repository);
      await cubit.loadEmployees();
    });

    tearDown(() => cubit.close());

    testWidgets('desactivar actualiza la tarjeta y recalcula los contadores', (
      tester,
    ) async {
      when(
        () => repository.updateEmployeeStatus(id: 'emp-1', isActive: false),
      ).thenAnswer((_) async => employees.first.copyWith(isActive: false));

      await pumpPage(tester, cubit);
      expectSummary(total: 3, active: 2, inactive: 1);

      await tester.tap(inCard('emp-1', find.byType(Switch)));
      await tester.pumpAndSettle();

      expect(cubit.state.employees.first.isActive, isFalse);
      expect(switchValue(tester, 'emp-1'), isFalse);
      expect(inCard('emp-1', find.text('Inactivo')), findsOneWidget);
      expect(switchValue(tester, 'emp-2'), isTrue);
      expect(inCard('emp-2', find.text('Activo')), findsOneWidget);
      expect(switchValue(tester, 'emp-3'), isFalse);
      expectSummary(total: 3, active: 1, inactive: 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el interruptor refleja cambios emitidos por el Cubit', (
      tester,
    ) async {
      when(
        () => repository.updateEmployeeStatus(id: 'emp-3', isActive: true),
      ).thenAnswer((_) async => employees[2].copyWith(isActive: true));

      await pumpPage(tester, cubit);
      expect(switchValue(tester, 'emp-3'), isFalse);

      // El cambio no proviene del interruptor sino directamente del Cubit.
      await cubit.updateEmployeeStatus(id: 'emp-3', isActive: true);
      await tester.pumpAndSettle();

      expect(cubit.state.employees[2].isActive, isTrue);
      expect(switchValue(tester, 'emp-3'), isTrue);
      expect(inCard('emp-3', find.text('Activo')), findsOneWidget);
      expect(switchValue(tester, 'emp-1'), isTrue);
      expect(switchValue(tester, 'emp-2'), isTrue);
    });

    testWidgets('un fallo al cambiar el estado no se muestra como éxito', (
      tester,
    ) async {
      when(
        () => repository.updateEmployeeStatus(id: 'emp-1', isActive: false),
      ).thenThrow(
        const EmployeeRepositoryException('No se pudo actualizar el estado.'),
      );

      await pumpPage(tester, cubit);
      await tester.tap(inCard('emp-1', find.byType(Switch)));
      await tester.pumpAndSettle();

      expect(cubit.state.status, EmployeeStatus.failure);
      expect(switchValue(tester, 'emp-1'), isTrue);
      expect(inCard('emp-1', find.text('Activo')), findsOneWidget);
      expectSummary(total: 3, active: 2, inactive: 1);
      expect(find.text('No se pudo actualizar el estado.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reintentar tras un error de carga muestra la lista', (
      tester,
    ) async {
      var attempts = 0;
      when(() => repository.getEmployees()).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw const EmployeeRepositoryException('Sin conexión.');
        }
        return employees;
      });
      final failingCubit = EmployeeCubit(repository);
      addTearDown(failingCubit.close);
      await failingCubit.loadEmployees();

      await pumpPage(tester, failingCubit);
      expect(find.text(EmployeesPage.loadErrorTitle), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text(EmployeesPage.loadErrorTitle), findsNothing);
      expect(find.byType(EmployeeCard), findsNWidgets(3));
      expectSummary(total: 3, active: 2, inactive: 1);
      expect(tester.takeException(), isNull);
    });
  });
}
