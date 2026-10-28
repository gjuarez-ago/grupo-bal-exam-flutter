import 'package:employee_management/features/employees/domain/entities/employee.dart';
import 'package:employee_management/features/employees/presentation/widgets/employee_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final employee = Employee(
    id: 'emp-1',
    fullName: 'Ana Sofía López Ramírez',
    area: 'Tecnología',
    position: 'Desarrolladora Flutter',
    gender: Gender.female,
    entryDate: DateTime(2021, 2, 5),
    birthDate: DateTime(1993, 6, 4),
    isActive: true,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required Employee employee,
    bool enabled = true,
    ValueChanged<bool>? onStatusChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeCard(
            employee: employee,
            statusControlEnabled: enabled,
            onStatusChanged: onStatusChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  Switch findSwitch(WidgetTester tester) => tester.widget<Switch>(
    find.descendant(
      of: find.byKey(EmployeeCard.statusSwitchKey('emp-1')),
      matching: find.byType(Switch),
    ),
  );

  Card cardOf(WidgetTester tester) => tester.widget<Card>(
    find.descendant(of: find.byType(EmployeeCard), matching: find.byType(Card)),
  );

  double contentOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.byKey(EmployeeCard.contentKey('emp-1')))
      .opacity;

  group('EmployeeCard', () {
    testWidgets('muestra los datos principales del empleado', (tester) async {
      await pumpCard(tester, employee: employee);

      expect(find.text('Ana Sofía López Ramírez'), findsOneWidget);
      expect(find.text('Tecnología'), findsOneWidget);
      expect(find.text('Desarrolladora Flutter'), findsOneWidget);
      expect(find.text('Femenino'), findsOneWidget);
      expect(find.text('Entrada: 05/02/2021'), findsOneWidget);
    });

    testWidgets('un empleado activo muestra "Activo" y el switch encendido', (
      tester,
    ) async {
      await pumpCard(tester, employee: employee);

      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Inactivo'), findsNothing);
      expect(findSwitch(tester).value, isTrue);
    });

    testWidgets('un empleado inactivo muestra "Inactivo" y el switch apagado', (
      tester,
    ) async {
      await pumpCard(tester, employee: employee.copyWith(isActive: false));

      expect(find.text('Inactivo'), findsOneWidget);
      expect(find.text('Activo'), findsNothing);
      expect(findSwitch(tester).value, isFalse);
    });

    testWidgets('un empleado activo se muestra con su apariencia normal', (
      tester,
    ) async {
      await pumpCard(tester, employee: employee);

      expect(cardOf(tester).color, isNull);
      expect(contentOpacity(tester), 1.0);
    });

    testWidgets('un empleado inactivo se muestra atenuado', (tester) async {
      await pumpCard(tester, employee: employee.copyWith(isActive: false));

      final context = tester.element(find.byType(EmployeeCard));
      expect(
        cardOf(tester).color,
        Theme.of(context).colorScheme.surfaceContainerHighest,
      );
      expect(contentOpacity(tester), EmployeeCard.inactiveOpacity);
      // El interruptor no se atenúa: debe seguir siendo fácil de usar.
      expect(
        find.ancestor(
          of: find.byKey(EmployeeCard.statusSwitchKey('emp-1')),
          matching: find.byType(AnimatedOpacity),
        ),
        findsNothing,
      );
    });

    testWidgets('el género masculino se muestra como "Masculino"', (
      tester,
    ) async {
      await pumpCard(tester, employee: employee.copyWith(gender: Gender.male));

      expect(find.text('Masculino'), findsOneWidget);
    });

    testWidgets('el género otro se muestra como "Otro"', (tester) async {
      await pumpCard(tester, employee: employee.copyWith(gender: Gender.other));

      expect(find.text('Otro'), findsOneWidget);
    });

    testWidgets('al pulsar el switch notifica el nuevo valor', (tester) async {
      bool? received;
      await pumpCard(
        tester,
        employee: employee,
        onStatusChanged: (value) => received = value,
      );

      await tester.tap(find.byType(Switch));

      expect(received, isFalse);
    });

    testWidgets('deshabilitado no responde a pulsaciones', (tester) async {
      var calls = 0;
      await pumpCard(
        tester,
        employee: employee,
        enabled: false,
        onStatusChanged: (_) => calls++,
      );

      await tester.tap(find.byType(Switch));

      expect(calls, 0);
      expect(findSwitch(tester).onChanged, isNull);
    });
  });
}
