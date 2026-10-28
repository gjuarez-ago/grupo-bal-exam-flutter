import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/employee_cubit.dart';
import '../cubit/employee_state.dart';
import '../widgets/employee_card.dart';
import '../widgets/employee_list_summary.dart';

/// Pantalla de listado de empleados.
///
/// Toma el [EmployeeCubit] del árbol; la carga inicial la dispara quien crea
/// el Cubit, por lo que no se repite al reconstruir esta pantalla.
class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  static const emptyMessage = 'Todavía no hay empleados registrados.';
  static const loadErrorTitle = 'No se pudieron cargar los empleados.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<EmployeeCubit, EmployeeState>(
          // Con datos en pantalla, un fallo (por ejemplo, al cambiar un
          // estado) se informa con un SnackBar y la lista conserva el estado
          // real que mantiene el Cubit.
          listenWhen: (previous, current) =>
              current.status == EmployeeStatus.failure &&
              previous.status != EmployeeStatus.failure &&
              current.employees.isNotEmpty,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ?? EmployeeCubit.unexpectedErrorMessage,
                  ),
                ),
              );
          },
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PageHeader(),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EmployeeState state) {
    if (state.employees.isNotEmpty) {
      return _EmployeeList(state: state);
    }
    return switch (state.status) {
      EmployeeStatus.initial || EmployeeStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      EmployeeStatus.failure => _MessageView(
        icon: Icons.cloud_off_outlined,
        title: loadErrorTitle,
        message: state.errorMessage,
        action: FilledButton.icon(
          onPressed: () => context.read<EmployeeCubit>().loadEmployees(),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
      EmployeeStatus.success => const _MessageView(
        icon: Icons.groups_outlined,
        title: emptyMessage,
      ),
    };
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Empleados',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Consulta y administra tu equipo',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.state});

  final EmployeeState state;

  @override
  Widget build(BuildContext context) {
    final employees = state.employees;
    // Mientras hay una operación en curso los interruptores se deshabilitan
    // para evitar cambios simultáneos.
    final controlsEnabled = state.status != EmployeeStatus.loading;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: employees.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 16 : 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return EmployeeListSummary(
            total: state.totalCount,
            active: state.activeCount,
            inactive: state.inactiveCount,
          );
        }
        final employee = employees[index - 1];
        return EmployeeCard(
          key: ValueKey(employee.id),
          employee: employee,
          statusControlEnabled: controlsEnabled,
          onStatusChanged: (isActive) => context
              .read<EmployeeCubit>()
              .updateEmployeeStatus(id: employee.id, isActive: isActive),
        );
      },
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
