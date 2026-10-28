import 'package:equatable/equatable.dart';

import '../../domain/entities/employee.dart';

/// Fase en la que se encuentra la carga de empleados.
enum EmployeeStatus { initial, loading, success, failure }

/// Estado inmutable de la funcionalidad de empleados.
///
/// Se usa una única clase con [status] en lugar de una clase por estado para
/// conservar la lista de empleados entre transiciones (por ejemplo, durante
/// una recarga). [errorMessage] solo tiene valor cuando [status] es
/// [EmployeeStatus.failure].
class EmployeeState extends Equatable {
  const EmployeeState({
    this.status = EmployeeStatus.initial,
    this.employees = const [],
    this.errorMessage,
  });

  final EmployeeStatus status;
  final List<Employee> employees;
  final String? errorMessage;

  /// Totales derivados de [employees]; nunca se almacenan por separado.
  int get totalCount => employees.length;
  int get activeCount =>
      employees.where((employee) => employee.isActive).length;
  int get inactiveCount => totalCount - activeCount;

  EmployeeState copyWith({
    EmployeeStatus? status,
    List<Employee>? employees,
    String? errorMessage,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      employees: employees != null
          ? List.unmodifiable(employees)
          : this.employees,
      // El mensaje de error no se arrastra: solo existe en el estado de fallo.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, employees, errorMessage];
}
