import 'package:employee_management/app.dart';
import 'package:employee_management/features/employees/data/datasources/employee_local_data_source.dart';
import 'package:employee_management/features/employees/data/datasources/employee_mock_data.dart';
import 'package:employee_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/domain/repositories/employee_repository.dart';
import 'package:employee_management/features/employees/presentation/cubit/employee_cubit.dart';
import 'package:employee_management/features/employees/presentation/pages/employee_form_page.dart';
import 'package:employee_management/features/employees/presentation/pages/employees_page.dart';
import 'package:employee_management/features/employees/presentation/widgets/employee_card.dart';
import 'package:employee_management/features/employees/presentation/widgets/employee_list_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/employee_form_helpers.dart';

class MockEmployeeRepository extends Mock implements EmployeeRepository {}

/// Flujo completo entre pantallas: listado → formulario → éxito → listado.
void main() {
  final today = DateTime(2026, 10, 27);

  setUpAll(() {
    registerFallbackValue(Gender.male);
    registerFallbackValue(DateTime(2000));
  });

  Future<EmployeeCubit> pumpApp(
    WidgetTester tester,
    EmployeeRepository repository,
  ) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final cubit = EmployeeCubit(repository);
    addTearDown(cubit.close);
    await cubit.loadEmployees();

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: EmployeeManagementApp.locale,
          supportedLocales: const [EmployeeManagementApp.locale],
          localizationsDelegates: EmployeeManagementApp.localizationsDelegates,
          home: EmployeesPage(today: today),
        ),
      ),
    );
    return cubit;
  }

  void expectSummary(int total, int active, int inactive) {
    Finder value(Key key, int count) =>
        find.descendant(of: find.byKey(key), matching: find.text('$count'));

    expect(value(EmployeeListSummary.totalKey, total), findsOneWidget);
    expect(value(EmployeeListSummary.activeKey, active), findsOneWidget);
    expect(value(EmployeeListSummary.inactiveKey, inactive), findsOneWidget);
  }

  testWidgets(
    'registrar desde el listado agrega al empleado y actualiza los totales',
    (tester) async {
      final cubit = await pumpApp(
        tester,
        EmployeeRepositoryImpl(EmployeeLocalDataSource()),
      );
      expectSummary(5, 4, 1);

      await tester.tap(find.text('Nuevo empleado'));
      await tester.pumpAndSettle();
      expect(find.byType(EmployeeFormPage), findsOneWidget);

      await fillValidEmployeeForm(tester);
      await submitEmployeeForm(tester);
      expect(find.text('Empleado registrado'), findsOneWidget);

      await tester.tap(find.text('Volver al listado'));
      await tester.pumpAndSettle();

      expect(find.byType(EmployeesPage), findsOneWidget);
      expect(find.byType(EmployeeCard), findsNWidgets(6));
      for (final employee in employeeMockData) {
        expect(find.text(employee.fullName), findsOneWidget);
      }
      final registered = cubit.state.employees.last;
      expect(registered.fullName, 'Luis Ramírez');
      expect(registered.isActive, isTrue);
      expect(find.text('Luis Ramírez'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ValueKey(registered.id)),
          matching: find.text('Ingreso: 15/10/2026'),
        ),
        findsOneWidget,
      );
      expectSummary(6, 5, 1);

      // El listado sigue funcionando: se puede desactivar al nuevo empleado.
      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey(registered.id)),
          matching: find.byType(Switch),
        ),
      );
      await tester.pumpAndSettle();
      expectSummary(6, 4, 2);
    },
  );

  testWidgets(
    'un registro fallido no agrega al empleado y cancelar vuelve al listado',
    (tester) async {
      final repository = MockEmployeeRepository();
      when(
        () => repository.getEmployees(),
      ).thenAnswer((_) async => employeeMockData);
      when(
        () => repository.registerEmployee(
          fullName: any(named: 'fullName'),
          area: any(named: 'area'),
          position: any(named: 'position'),
          gender: any(named: 'gender'),
          entryDate: any(named: 'entryDate'),
          birthDate: any(named: 'birthDate'),
        ),
      ).thenThrow(
        const EmployeeRepositoryException('No se pudo registrar al empleado.'),
      );
      final cubit = await pumpApp(tester, repository);

      await tester.tap(find.text('Nuevo empleado'));
      await tester.pumpAndSettle();
      await fillValidEmployeeForm(tester);
      await submitEmployeeForm(tester);

      // El error se informa una sola vez, en el formulario.
      expect(find.text('No se pudo registrar al empleado.'), findsOneWidget);
      expect(find.text('Empleado registrado'), findsNothing);
      expect(cubit.state.employees, employeeMockData);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeCard), findsNWidgets(5));
      expect(find.text('Luis Ramírez'), findsNothing);
      expectSummary(5, 4, 1);
    },
  );
}
