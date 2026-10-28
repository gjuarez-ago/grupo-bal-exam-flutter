import 'package:employee_management/features/employees/presentation/pages/employee_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pasos compartidos por las pruebas que interactúan con el formulario de
/// registro.

Future<void> selectFormOption(
  WidgetTester tester,
  Key field,
  String option,
) async {
  await tester.tap(find.byKey(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// Abre el selector de fecha de [field], elige el día [day] del mes que
/// muestra al abrirse y confirma.
Future<void> pickFormDay(WidgetTester tester, Key field, String day) async {
  await tester.tap(find.byKey(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(day));
  await tester.tap(find.text('Aceptar'));
  await tester.pumpAndSettle();
}

/// Completa el formulario con datos válidos. Con la fecha de referencia
/// 27/10/2026, el ingreso queda en 15/10/2026 y el nacimiento en 10/10/1996.
Future<void> fillValidEmployeeForm(
  WidgetTester tester, {
  String fullName = '  Luis Ramírez  ',
  String position = ' QA ',
  bool selectArea = true,
  bool selectGender = true,
}) async {
  await tester.enterText(find.byKey(EmployeeFormPage.fullNameKey), fullName);
  await tester.enterText(find.byKey(EmployeeFormPage.positionKey), position);
  if (selectArea) {
    await selectFormOption(tester, EmployeeFormPage.areaKey, 'Tecnología');
  }
  if (selectGender) {
    await selectFormOption(tester, EmployeeFormPage.genderKey, 'Masculino');
  }
  await pickFormDay(tester, EmployeeFormPage.entryDateKey, '15');
  await pickFormDay(tester, EmployeeFormPage.birthDateKey, '10');
}

Future<void> submitEmployeeForm(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Registrar empleado'));
  await tester.pumpAndSettle();
}
