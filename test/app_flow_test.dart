import 'package:employee_management/app.dart';
import 'package:employee_management/features/employees/data/datasources/employee_local_data_source.dart';
import 'package:employee_management/features/employees/data/datasources/employee_mock_data.dart';
import 'package:employee_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:employee_management/features/employees/presentation/cubit/employee_cubit.dart';
import 'package:employee_management/features/employees/presentation/pages/employee_form_page.dart';
import 'package:employee_management/features/employees/presentation/pages/employee_registration_success_page.dart';
import 'package:employee_management/features/employees/presentation/pages/employees_page.dart';
import 'package:employee_management/features/employees/presentation/widgets/employee_card.dart';
import 'package:employee_management/features/employees/presentation/widgets/employee_list_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/employee_form_helpers.dart';

/// Repositorio en memoria real que cuenta las llamadas y puede simular fallos.
class CountingEmployeeRepository implements EmployeeRepository {
  CountingEmployeeRepository({
    this.failFirstLoad = false,
    this.failRegistration = false,
  });

  final bool failFirstLoad;
  final bool failRegistration;
  final _delegate = EmployeeRepositoryImpl(EmployeeLocalDataSource());

  int loadCalls = 0;
  int registerCalls = 0;

  @override
  Future<List<Employee>> getEmployees() async {
    loadCalls++;
    if (failFirstLoad && loadCalls == 1) {
      throw const EmployeeRepositoryException('Sin conexión.');
    }
    return _delegate.getEmployees();
  }

  @override
  Future<Employee> registerEmployee({
    required String fullName,
    required String area,
    required String position,
    required Gender gender,
    required DateTime entryDate,
    required DateTime birthDate,
  }) async {
    registerCalls++;
    if (failRegistration) {
      throw const EmployeeRepositoryException(
        'No se pudo registrar al empleado.',
      );
    }
    return _delegate.registerEmployee(
      fullName: fullName,
      area: area,
      position: position,
      gender: gender,
      entryDate: entryDate,
      birthDate: birthDate,
    );
  }

  @override
  Future<Employee> updateEmployeeStatus({
    required String id,
    required bool isActive,
  }) => _delegate.updateEmployeeStatus(id: id, isActive: isActive);
}

final today = DateTime(2026, 10, 27);

Future<void> pumpApp(
  WidgetTester tester,
  EmployeeRepository repository, {
  Size physicalSize = const Size(1200, 6000),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    EmployeeManagementApp(employeeRepository: repository, today: today),
  );
  await tester.pumpAndSettle();
}

EmployeeCubit cubitOf(WidgetTester tester) => tester
    .element(find.byType(EmployeesPage, skipOffstage: false))
    .read<EmployeeCubit>();

Future<void> openForm(WidgetTester tester) async {
  await tester.tap(find.text('Nuevo empleado'));
  await tester.pumpAndSettle();
}

Future<void> registerValidEmployee(WidgetTester tester) async {
  await openForm(tester);
  await fillValidEmployeeForm(tester);
  await submitEmployeeForm(tester);
}

Future<void> backToList(WidgetTester tester) async {
  await tester.tap(find.text('Volver al listado'));
  await tester.pumpAndSettle();
}

Finder inCard(String employeeId, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(employeeId)), matching: matching);

void expectSummary(int total, int active, int inactive) {
  Finder value(Key key, int count) =>
      find.descendant(of: find.byKey(key), matching: find.text('$count'));

  expect(value(EmployeeListSummary.totalKey, total), findsOneWidget);
  expect(value(EmployeeListSummary.activeKey, active), findsOneWidget);
  expect(value(EmployeeListSummary.inactiveKey, inactive), findsOneWidget);
}

void main() {
  group('Navegación', () {
    testWidgets('la aplicación abre en el listado de empleados', (
      tester,
    ) async {
      final repository = CountingEmployeeRepository();
      await pumpApp(tester, repository);

      expect(find.text('Empleados'), findsOneWidget);
      expect(find.byType(EmployeeCard), findsNWidgets(5));
      expectSummary(5, 4, 1);
      expect(repository.loadCalls, 1);
    });

    testWidgets('Nuevo empleado abre el formulario', (tester) async {
      await pumpApp(tester, CountingEmployeeRepository());

      await openForm(tester);

      expect(find.byType(EmployeeFormPage), findsOneWidget);
      expect(find.text('Registrar empleado'), findsWidgets);
    });

    testWidgets('cancelar vuelve al listado sin registrar a nadie', (
      tester,
    ) async {
      final repository = CountingEmployeeRepository();
      await pumpApp(tester, repository);
      await openForm(tester);
      await fillValidEmployeeForm(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeFormPage), findsNothing);
      expect(find.byType(EmployeeCard), findsNWidgets(5));
      expect(find.text('Luis Ramírez'), findsNothing);
      expectSummary(5, 4, 1);
      expect(repository.registerCalls, 0);
    });

    testWidgets(
      'un registro exitoso confirma una sola vez y vuelve al listado',
      (tester) async {
        await pumpApp(tester, CountingEmployeeRepository());

        await registerValidEmployee(tester);

        expect(find.byType(EmployeeFormPage), findsNothing);
        expect(
          find.text(EmployeeRegistrationSuccessPage.title),
          findsOneWidget,
        );

        await backToList(tester);

        expect(find.byType(EmployeesPage), findsOneWidget);
        expect(find.text(EmployeeRegistrationSuccessPage.title), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(EmployeeCard), findsNWidgets(6));
      },
    );

    testWidgets('pulsaciones repetidas no apilan formularios', (tester) async {
      await pumpApp(tester, CountingEmployeeRepository());

      await tester.tap(find.text('Nuevo empleado'));
      await tester.tap(find.text('Nuevo empleado'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeFormPage), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeFormPage), findsNothing);
      expect(find.byType(EmployeeCard), findsNWidgets(5));

      // El botón vuelve a funcionar después de cerrar el formulario.
      await openForm(tester);
      expect(find.byType(EmployeeFormPage), findsOneWidget);
    });

    testWidgets('un error del repositorio no navega al éxito', (tester) async {
      final repository = CountingEmployeeRepository(failRegistration: true);
      await pumpApp(tester, repository);

      await registerValidEmployee(tester);

      expect(find.text(EmployeeRegistrationSuccessPage.title), findsNothing);
      expect(find.byType(EmployeeFormPage), findsOneWidget);
      expect(find.text('No se pudo registrar al empleado.'), findsOneWidget);
      expect(cubitOf(tester).state.employees, employeeMockData);

      // Se puede reintentar con los mismos datos.
      await submitEmployeeForm(tester);
      expect(repository.registerCalls, 2);
      expect(find.byType(EmployeeFormPage), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeCard), findsNWidgets(5));
      expectSummary(5, 4, 1);
    });
  });

  group('Estado compartido', () {
    testWidgets(
      'flujo completo: el empleado registrado aparece con sus datos',
      (tester) async {
        await pumpApp(tester, CountingEmployeeRepository());

        await registerValidEmployee(tester);
        await backToList(tester);

        final registered = cubitOf(tester).state.employees.last;
        expect(registered.fullName, 'Luis Ramírez');
        final card = find.byKey(ValueKey(registered.id));
        expect(card, findsOneWidget);
        for (final text in [
          'Luis Ramírez',
          'QA',
          'Tecnología',
          'Masculino',
          'Ingreso: 15/10/2026',
          'Activo',
        ]) {
          expect(inCard(registered.id, find.text(text)), findsOneWidget);
        }
        for (final employee in employeeMockData) {
          expect(find.text(employee.fullName), findsOneWidget);
        }
        expectSummary(6, 5, 1);
      },
    );

    testWidgets('los cambios de estado sobreviven a la navegación', (
      tester,
    ) async {
      await pumpApp(tester, CountingEmployeeRepository());

      await tester.tap(inCard('emp-1', find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(inCard('emp-1', find.text('Inactivo')), findsOneWidget);
      expectSummary(5, 3, 2);

      await openForm(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(inCard('emp-1', find.text('Inactivo')), findsOneWidget);

      await registerValidEmployee(tester);
      await backToList(tester);

      expect(inCard('emp-1', find.text('Inactivo')), findsOneWidget);
      expectSummary(6, 4, 2);
    });

    testWidgets('volver al listado no duplica empleados', (tester) async {
      final repository = CountingEmployeeRepository();
      await pumpApp(tester, repository);

      await registerValidEmployee(tester);
      await backToList(tester);
      for (var i = 0; i < 2; i++) {
        await openForm(tester);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
      }

      final employees = cubitOf(tester).state.employees;
      expect(repository.registerCalls, 1);
      expect(employees.length, 6);
      expect(employees.map((e) => e.id).toSet().length, 6);
      expect(find.text('Luis Ramírez'), findsOneWidget);
      expect(find.byType(EmployeeCard), findsNWidgets(6));
    });

    testWidgets('reconstruir la app no recrea el Cubit ni recarga los datos', (
      tester,
    ) async {
      final repository = CountingEmployeeRepository();
      await pumpApp(tester, repository);
      final cubitBefore = cubitOf(tester);

      await registerValidEmployee(tester);
      await backToList(tester);
      await tester.pumpWidget(
        EmployeeManagementApp(employeeRepository: repository, today: today),
      );
      await tester.pumpAndSettle();

      expect(identical(cubitOf(tester), cubitBefore), isTrue);
      expect(repository.loadCalls, 1);
      expect(find.byType(EmployeeCard), findsNWidgets(6));
      expectSummary(6, 5, 1);
    });

    testWidgets('reintentar una carga fallida muestra la lista', (
      tester,
    ) async {
      final repository = CountingEmployeeRepository(failFirstLoad: true);
      await pumpApp(tester, repository);

      expect(find.text(EmployeesPage.loadErrorTitle), findsOneWidget);
      expect(find.text('Sin conexión.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(repository.loadCalls, 2);
      expect(find.byType(EmployeeCard), findsNWidgets(5));
      expectSummary(5, 4, 1);
    });
  });

  testWidgets(
    'el formulario se puede usar con el teclado abierto en un móvil pequeño',
    (tester) async {
      await pumpApp(
        tester,
        CountingEmployeeRepository(),
        physicalSize: const Size(960, 1704),
      );
      await openForm(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 780);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final submit = find.widgetWithText(FilledButton, 'Registrar empleado');
      await tester.scrollUntilVisible(
        submit,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(submit.hitTestable(), findsOneWidget);
    },
  );
}
