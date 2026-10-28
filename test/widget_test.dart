import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:employee_management/app.dart';

void main() {
  testWidgets('La aplicación arranca y muestra el título', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EmployeeManagementApp());

    expect(find.text('Gestión de empleados'), findsOneWidget);
  });

  testWidgets('La aplicación usa el tema Material 3', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EmployeeManagementApp());

    final context = tester.element(find.text('Gestión de empleados'));
    expect(Theme.of(context).useMaterial3, isTrue);
  });
}
