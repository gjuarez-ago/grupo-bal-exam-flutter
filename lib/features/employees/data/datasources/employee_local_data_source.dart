import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';
import 'employee_mock_data.dart';

/// Fuente de datos local que guarda los empleados en memoria.
///
/// Los cambios se pierden al reiniciar la aplicación. Nunca expone su lista
/// interna: las consultas devuelven copias no modificables.
class EmployeeLocalDataSource {
  EmployeeLocalDataSource({List<Employee>? initialEmployees})
    : _employees = List.of(initialEmployees ?? employeeMockData);

  final List<Employee> _employees;
  int _idSequence = 0;

  List<Employee> getEmployees() => List.unmodifiable(_employees);

  /// Agrega un empleado activo con un identificador único y lo devuelve.
  Employee addEmployee({
    required String fullName,
    required String area,
    required String position,
    required Gender gender,
    required DateTime entryDate,
    required DateTime birthDate,
  }) {
    final employee = Employee(
      id: _generateId(),
      fullName: fullName,
      area: area,
      position: position,
      gender: gender,
      entryDate: entryDate,
      birthDate: birthDate,
      isActive: true,
    );
    _employees.add(employee);
    return employee;
  }

  /// Cambia el estado activo del empleado [id] y devuelve su versión
  /// actualizada.
  ///
  /// Lanza [EmployeeNotFoundException] si el empleado no existe.
  Employee updateEmployeeStatus({required String id, required bool isActive}) {
    final index = _employees.indexWhere((employee) => employee.id == id);
    if (index == -1) {
      throw EmployeeNotFoundException(id);
    }
    final updated = _employees[index].copyWith(isActive: isActive);
    _employees[index] = updated;
    return updated;
  }

  /// Genera `emp-N` evitando colisiones con los identificadores existentes.
  String _generateId() {
    String id;
    do {
      _idSequence++;
      id = 'emp-$_idSequence';
    } while (_employees.any((employee) => employee.id == id));
    return id;
  }
}
