import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:employee_management/app.dart';
import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/presentation/cubit/employee_cubit.dart';
import 'package:employee_management/features/employees/presentation/cubit/employee_state.dart';
import 'package:employee_management/features/employees/presentation/pages/employee_form_page.dart';
import 'package:employee_management/features/employees/presentation/pages/employee_registration_success_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/employee_form_helpers.dart';

class MockEmployeeCubit extends MockCubit<EmployeeState>
    implements EmployeeCubit {}

final today = DateTime(2026, 10, 27);

void main() {
  late MockEmployeeCubit cubit;

  setUpAll(() {
    registerFallbackValue(Gender.male);
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    cubit = MockEmployeeCubit();
    whenListen(
      cubit,
      const Stream<EmployeeState>.empty(),
      initialState: const EmployeeState(status: EmployeeStatus.success),
    );
  });

  When<Future<bool>> whenRegister() => when(
    () => cubit.registerEmployee(
      fullName: any(named: 'fullName'),
      area: any(named: 'area'),
      position: any(named: 'position'),
      gender: any(named: 'gender'),
      entryDate: any(named: 'entryDate'),
      birthDate: any(named: 'birthDate'),
    ),
  );

  void verifyNeverRegistered() => verifyNever(
    () => cubit.registerEmployee(
      fullName: any(named: 'fullName'),
      area: any(named: 'area'),
      position: any(named: 'position'),
      gender: any(named: 'gender'),
      entryDate: any(named: 'entryDate'),
      birthDate: any(named: 'birthDate'),
    ),
  );

  /// Monta una pantalla de inicio desde la que se abre el formulario, para
  /// poder comprobar la navegación de regreso.
  Future<void> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<EmployeeCubit>.value(
        value: cubit,
        child: MaterialApp(
          locale: EmployeeManagementApp.locale,
          supportedLocales: const [EmployeeManagementApp.locale],
          localizationsDelegates: EmployeeManagementApp.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EmployeeFormPage(today: today),
                    ),
                  ),
                  child: const Text('Inicio'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
  }

  DatePickerDialog openedPicker(WidgetTester tester) =>
      tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));

  group('EmployeeFormPage — campos', () {
    testWidgets('muestra todos los campos y acciones', (tester) async {
      await openForm(tester);

      expect(find.text('Registrar empleado'), findsNWidgets(2));
      for (final label in [
        'Nombre completo',
        'Puesto',
        'Área',
        'Género',
        'Fecha de entrada',
        'Fecha de nacimiento',
        'Cancelar',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('los selectores ofrecen todas las áreas y géneros', (
      tester,
    ) async {
      await openForm(tester);

      await tester.tap(find.byKey(EmployeeFormPage.areaKey));
      await tester.pumpAndSettle();
      for (final area in [
        'Administración',
        'Finanzas',
        'Operaciones',
        'Recursos Humanos',
        'Tecnología',
        'Ventas',
      ]) {
        expect(find.text(area), findsWidgets, reason: area);
      }
      await tester.tap(find.text('Administración').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(EmployeeFormPage.genderKey));
      await tester.pumpAndSettle();
      for (final gender in ['Masculino', 'Femenino', 'Otro']) {
        expect(find.text(gender), findsWidgets, reason: gender);
      }
      await tester.tap(find.text('Otro').last);
      await tester.pumpAndSettle();

      expect(find.text('Administración'), findsOneWidget);
      expect(find.text('Otro'), findsOneWidget);
    });

    testWidgets('las fechas elegidas se muestran como dd/MM/yyyy', (
      tester,
    ) async {
      await openForm(tester);

      await fillValidEmployeeForm(tester);

      expect(find.text('15/10/2026'), findsOneWidget);
      expect(find.text('10/10/1996'), findsOneWidget);
    });
  });

  group('EmployeeFormPage — validaciones', () {
    testWidgets('un formulario vacío muestra todos los errores', (
      tester,
    ) async {
      await openForm(tester);

      await submitEmployeeForm(tester);

      for (final message in [
        'Ingresa el nombre completo.',
        'Ingresa el puesto.',
        'Selecciona un área.',
        'Selecciona un género.',
        'Selecciona la fecha de entrada.',
        'Selecciona la fecha de nacimiento.',
      ]) {
        expect(find.text(message), findsOneWidget, reason: message);
      }
      verifyNeverRegistered();
    });

    testWidgets('un nombre con solo espacios impide registrar', (tester) async {
      await openForm(tester);
      await fillValidEmployeeForm(tester, fullName: '   ');

      await submitEmployeeForm(tester);

      expect(find.text('Ingresa el nombre completo.'), findsOneWidget);
      verifyNeverRegistered();
    });

    testWidgets('un puesto vacío impide registrar', (tester) async {
      await openForm(tester);
      await fillValidEmployeeForm(tester, position: '');

      await submitEmployeeForm(tester);

      expect(find.text('Ingresa el puesto.'), findsOneWidget);
      verifyNeverRegistered();
    });

    testWidgets('no seleccionar área impide registrar', (tester) async {
      await openForm(tester);
      await fillValidEmployeeForm(tester, selectArea: false);

      await submitEmployeeForm(tester);

      expect(find.text('Selecciona un área.'), findsOneWidget);
      verifyNeverRegistered();
    });

    testWidgets('no seleccionar género impide registrar', (tester) async {
      await openForm(tester);
      await fillValidEmployeeForm(tester, selectGender: false);

      await submitEmployeeForm(tester);

      expect(find.text('Selecciona un género.'), findsOneWidget);
      verifyNeverRegistered();
    });

    testWidgets('los selectores no permiten fechas futuras', (tester) async {
      await openForm(tester);

      await tester.tap(find.byKey(EmployeeFormPage.entryDateKey));
      await tester.pumpAndSettle();
      expect(openedPicker(tester).lastDate, today);
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(EmployeeFormPage.birthDateKey));
      await tester.pumpAndSettle();
      expect(openedPicker(tester).lastDate, DateTime(2026, 10, 26));
    });

    testWidgets('las fechas solo se eligen en el calendario, sin escribirlas', (
      tester,
    ) async {
      await openForm(tester);

      for (final field in [
        EmployeeFormPage.entryDateKey,
        EmployeeFormPage.birthDateKey,
      ]) {
        await tester.tap(find.byKey(field));
        await tester.pumpAndSettle();

        expect(
          openedPicker(tester).initialEntryMode,
          DatePickerEntryMode.calendarOnly,
        );
        // No hay botón para cambiar al modo de escritura ni campo de texto.
        expect(find.byIcon(Icons.edit_outlined), findsNothing);
        expect(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.byType(TextField),
          ),
          findsNothing,
        );

        await tester.tap(find.text('Cancelar').last);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('el nacimiento no puede elegirse en o después de la entrada', (
      tester,
    ) async {
      await openForm(tester);
      await pickFormDay(tester, EmployeeFormPage.entryDateKey, '15');

      await tester.tap(find.byKey(EmployeeFormPage.birthDateKey));
      await tester.pumpAndSettle();

      expect(openedPicker(tester).lastDate, DateTime(2026, 10, 14));
    });
  });

  group('EmployeeFormPage — envío', () {
    testWidgets('un formulario válido registra con los datos depurados', (
      tester,
    ) async {
      whenRegister().thenAnswer((_) async => true);
      await openForm(tester);
      await fillValidEmployeeForm(tester);

      await submitEmployeeForm(tester);

      verify(
        () => cubit.registerEmployee(
          fullName: 'Luis Ramírez',
          area: 'Tecnología',
          position: 'QA',
          gender: Gender.male,
          entryDate: DateTime(2026, 10, 15),
          birthDate: DateTime(1996, 10, 10),
        ),
      ).called(1);
      expect(find.text(EmployeeRegistrationSuccessPage.title), findsOneWidget);
      expect(find.textContaining('Luis Ramírez ya aparece'), findsOneWidget);

      await tester.tap(find.text('Regresar a empleados'));
      await tester.pumpAndSettle();
      expect(find.text('Inicio'), findsOneWidget);
    });

    testWidgets('un error del registro se muestra y permite reintentar', (
      tester,
    ) async {
      whenListen(
        cubit,
        const Stream<EmployeeState>.empty(),
        initialState: const EmployeeState(
          status: EmployeeStatus.failure,
          errorMessage: 'No se pudo registrar al empleado.',
        ),
      );
      whenRegister().thenAnswer((_) async => false);
      await openForm(tester);
      await fillValidEmployeeForm(tester);

      await submitEmployeeForm(tester);

      expect(find.byKey(EmployeeFormPage.submitErrorKey), findsOneWidget);
      expect(find.text('No se pudo registrar al empleado.'), findsOneWidget);
      expect(find.text(EmployeeRegistrationSuccessPage.title), findsNothing);
      // Los datos se conservan y el botón vuelve a estar disponible.
      expect(find.text('  Luis Ramírez  '), findsOneWidget);
      expect(find.text('15/10/2026'), findsOneWidget);

      await submitEmployeeForm(tester);

      verify(
        () => cubit.registerEmployee(
          fullName: 'Luis Ramírez',
          area: any(named: 'area'),
          position: any(named: 'position'),
          gender: any(named: 'gender'),
          entryDate: any(named: 'entryDate'),
          birthDate: any(named: 'birthDate'),
        ),
      ).called(2);
    });

    testWidgets('pulsaciones repetidas registran una sola vez', (tester) async {
      final completer = Completer<bool>();
      whenRegister().thenAnswer((_) => completer.future);
      await openForm(tester);
      await fillValidEmployeeForm(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Registrar empleado'));
      await tester.pump();
      expect(find.text('Registrando…'), findsOneWidget);
      await tester.tap(find.text('Registrando…'));
      await tester.pump();

      completer.complete(true);
      await tester.pumpAndSettle();

      verify(
        () => cubit.registerEmployee(
          fullName: any(named: 'fullName'),
          area: any(named: 'area'),
          position: any(named: 'position'),
          gender: any(named: 'gender'),
          entryDate: any(named: 'entryDate'),
          birthDate: any(named: 'birthDate'),
        ),
      ).called(1);
      expect(find.text(EmployeeRegistrationSuccessPage.title), findsOneWidget);
    });

    testWidgets('cancelar regresa sin registrar', (tester) async {
      await openForm(tester);
      await fillValidEmployeeForm(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      verifyNeverRegistered();
    });
  });
}
