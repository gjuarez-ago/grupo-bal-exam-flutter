import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/employees/domain/repositories/employee_repository.dart';
import 'features/employees/presentation/cubit/employee_cubit.dart';
import 'features/employees/presentation/pages/employees_page.dart';

/// Widget raíz de la aplicación.
///
/// Recibe el [EmployeeRepository] ya construido y lo pone a disposición del
/// árbol junto con el [EmployeeCubit]. No conoce la implementación concreta.
class EmployeeManagementApp extends StatelessWidget {
  const EmployeeManagementApp({super.key, required this.employeeRepository});

  final EmployeeRepository employeeRepository;

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
          home: const EmployeesPage(),
        ),
      ),
    );
  }
}
