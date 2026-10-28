import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/employees/domain/repositories/employee_repository.dart';
import 'features/employees/presentation/cubit/employee_cubit.dart';
import 'features/employees/presentation/pages/employees_page.dart';

/// Widget raíz de la aplicación.
///
/// Recibe el [EmployeeRepository] ya construido y lo pone a disposición del
/// árbol junto con el [EmployeeCubit]. No conoce la implementación concreta.
///
/// El Cubit se crea una sola vez, por encima de [MaterialApp], de modo que
/// todas las rutas (listado, formulario y confirmación) comparten la misma
/// instancia y el mismo estado durante la sesión.
class EmployeeManagementApp extends StatelessWidget {
  const EmployeeManagementApp({
    super.key,
    required this.employeeRepository,
    this.today,
  });

  final EmployeeRepository employeeRepository;

  /// Fecha de referencia para las validaciones del registro. Por defecto, la
  /// fecha actual; las pruebas la fijan para ser deterministas.
  @visibleForTesting
  final DateTime? today;

  /// Idioma de la interfaz: los componentes de Material (por ejemplo, el
  /// selector de fechas) se muestran en español.
  static const locale = Locale('es', 'MX');
  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: employeeRepository,
      child: BlocProvider(
        // La carga inicial se ejecuta una sola vez, al crear el Cubit.
        create: (_) => EmployeeCubit(employeeRepository)..loadEmployees(),
        child: MaterialApp(
          title: 'Gestión de empleados',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: const [locale],
          localizationsDelegates: localizationsDelegates,
          home: EmployeesPage(today: today),
        ),
      ),
    );
  }
}
