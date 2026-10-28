import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:employee_management/app.dart';
import 'package:employee_management/features/employees/data/datasources/employee_local_data_source.dart';
import 'package:employee_management/features/employees/data/datasources/employee_mock_data.dart';
import 'package:employee_management/features/employees/data/repositories/employee_repository_impl.dart';

void main() {
  Widget buildApp() => EmployeeManagementApp(
    employeeRepository: EmployeeRepositoryImpl(EmployeeLocalDataSource()),
  );

  testWidgets('La aplicación arranca y muestra el título', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('Gestión de empleados'), findsOneWidget);
  });

  testWidgets('La aplicación usa el tema Material 3', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());

    final context = tester.element(find.text('Gestión de empleados'));
    expect(Theme.of(context).useMaterial3, isTrue);
  });

  testWidgets('Carga los empleados ficticios a través del Cubit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Empleados registrados: ${employeeMockData.length}'),
      findsOneWidget,
    );
  });
}
