import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_local_data_source.dart';

/// Implementación de [EmployeeRepository] respaldada por la fuente local.
///
/// Las operaciones son `async`, de modo que cualquier excepción de la fuente
/// de datos llega al llamador como un [Future] fallido.
class EmployeeRepositoryImpl implements EmployeeRepository {
  EmployeeRepositoryImpl(this._localDataSource);

  final EmployeeLocalDataSource _localDataSource;

  @override
  Future<List<Employee>> getEmployees() async {
    return _localDataSource.getEmployees();
  }

  @override
  Future<Employee> registerEmployee({
    required String fullName,
    required String area,
    required String position,
    required Gender gender,
    required DateTime entryDate,
    required DateTime birthDate,
  }) async {
    return _localDataSource.addEmployee(
      fullName: fullName,
      area: area,
      position: position,
      gender: gender,
      entryDate: entryDate,
      birthDate: birthDate,
    );
  }

  @override
  Future<Employee> updateEmployeeStatus({
    required String id,
    required bool isActive,
  }) async {
    return _localDataSource.updateEmployeeStatus(id: id, isActive: isActive);
  }
}
