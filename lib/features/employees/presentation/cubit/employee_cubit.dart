import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';
import 'employee_state.dart';

/// Gestiona el estado de la funcionalidad de empleados.
///
/// Recibe el [EmployeeRepository] por constructor y no conoce su
/// implementación concreta. Ante un fallo conserva la lista vigente, de modo
/// que el Cubit puede seguir utilizándose.
class EmployeeCubit extends Cubit<EmployeeState> {
  EmployeeCubit(this._repository) : super(const EmployeeState());

  final EmployeeRepository _repository;

  static const unexpectedErrorMessage =
      'Ocurrió un error inesperado. Intenta de nuevo.';

  Future<void> loadEmployees() async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      final employees = await _repository.getEmployees();
      emit(
        state.copyWith(status: EmployeeStatus.success, employees: employees),
      );
    } catch (error, stackTrace) {
      _emitFailure(error, stackTrace);
    }
  }

  /// Registra un empleado y lo agrega a la lista actual.
  ///
  /// Devuelve `true` si el registro se completó.
  Future<bool> registerEmployee({
    required String fullName,
    required String area,
    required String position,
    required Gender gender,
    required DateTime entryDate,
    required DateTime birthDate,
  }) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      final employee = await _repository.registerEmployee(
        fullName: fullName,
        area: area,
        position: position,
        gender: gender,
        entryDate: entryDate,
        birthDate: birthDate,
      );
      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          employees: [...state.employees, employee],
        ),
      );
      return true;
    } catch (error, stackTrace) {
      _emitFailure(error, stackTrace);
      return false;
    }
  }

  /// Cambia el estado activo del empleado [id] y reemplaza solo ese empleado
  /// en la lista actual.
  ///
  /// Devuelve `true` si la actualización se completó.
  Future<bool> updateEmployeeStatus({
    required String id,
    required bool isActive,
  }) async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      final updated = await _repository.updateEmployeeStatus(
        id: id,
        isActive: isActive,
      );
      emit(
        state.copyWith(
          status: EmployeeStatus.success,
          employees: [
            for (final employee in state.employees)
              employee.id == updated.id ? updated : employee,
          ],
        ),
      );
      return true;
    } catch (error, stackTrace) {
      _emitFailure(error, stackTrace);
      return false;
    }
  }

  /// Emite el estado de fallo conservando la lista actual.
  ///
  /// Los errores esperados muestran su mensaje; los no previstos se notifican
  /// al BlocObserver con [addError] para no ocultarlos.
  void _emitFailure(Object error, StackTrace stackTrace) {
    final String message;
    if (error is EmployeeRepositoryException) {
      message = error.message;
    } else {
      addError(error, stackTrace);
      message = unexpectedErrorMessage;
    }
    emit(state.copyWith(status: EmployeeStatus.failure, errorMessage: message));
  }
}
