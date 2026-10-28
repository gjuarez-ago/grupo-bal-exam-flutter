import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/employee_repository.dart';
import 'employee_state.dart';

/// Gestiona el estado de la funcionalidad de empleados.
///
/// Recibe el [EmployeeRepository] por constructor y no conoce su
/// implementación concreta.
class EmployeeCubit extends Cubit<EmployeeState> {
  EmployeeCubit(this._repository) : super(const EmployeeState());

  final EmployeeRepository _repository;

  static const unexpectedErrorMessage =
      'Ocurrió un error inesperado al cargar los empleados.';

  Future<void> loadEmployees() async {
    emit(state.copyWith(status: EmployeeStatus.loading));
    try {
      final employees = await _repository.getEmployees();
      emit(
        state.copyWith(status: EmployeeStatus.success, employees: employees),
      );
    } on EmployeeRepositoryException catch (error) {
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (error, stackTrace) {
      // Los errores no previstos se notifican al BlocObserver para no
      // ocultarlos, y el usuario recibe un mensaje genérico.
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: EmployeeStatus.failure,
          errorMessage: unexpectedErrorMessage,
        ),
      );
    }
  }
}
