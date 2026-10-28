import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/employees/domain/repositories/employee_repository.dart';
import 'features/employees/presentation/cubit/employee_cubit.dart';
import 'features/employees/presentation/cubit/employee_state.dart';

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
        create: (_) => EmployeeCubit(employeeRepository)..loadEmployees(),
        child: MaterialApp(
          title: 'Gestión de empleados',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const _ProvisionalHome(),
        ),
      ),
    );
  }
}

/// Pantalla provisional que solo confirma la conexión con el Cubit.
///
/// Se sustituirá por el listado de empleados en la Fase 4.
class _ProvisionalHome extends StatelessWidget {
  const _ProvisionalHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BlocBuilder<EmployeeCubit, EmployeeState>(
          builder: (context, state) {
            final summary = switch (state.status) {
              EmployeeStatus.initial || EmployeeStatus.loading => 'Cargando…',
              EmployeeStatus.success =>
                'Empleados registrados: ${state.employees.length}',
              EmployeeStatus.failure => state.errorMessage ?? '',
            };
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gestión de empleados',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(summary),
              ],
            );
          },
        ),
      ),
    );
  }
}
