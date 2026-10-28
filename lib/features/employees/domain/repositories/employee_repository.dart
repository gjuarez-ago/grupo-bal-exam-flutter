import '../entities/employee.dart';

/// Error esperado al operar con el repositorio de empleados.
///
/// Las implementaciones deben lanzar esta excepción (o una subclase) ante
/// fallos previsibles, con un [message] comprensible para el usuario.
class EmployeeRepositoryException implements Exception {
  const EmployeeRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'EmployeeRepositoryException: $message';
}

/// Se lanza cuando no existe un empleado con el identificador indicado.
class EmployeeNotFoundException extends EmployeeRepositoryException {
  const EmployeeNotFoundException(String id)
    : super('No se encontró el empleado con id $id.');
}

/// Contrato de acceso a los empleados.
///
/// La capa de datos lo implementa; el dominio y la presentación solo dependen
/// de esta abstracción. Las operaciones devuelven [Future] para admitir
/// fuentes de datos asíncronas (red o almacenamiento) sin cambiar el contrato.
abstract class EmployeeRepository {
  /// Devuelve todos los empleados registrados. Una lista vacía es válida.
  Future<List<Employee>> getEmployees();

  /// Registra un empleado nuevo y lo devuelve con el [Employee.id] asignado
  /// por la implementación. Los empleados nuevos se registran como activos.
  Future<Employee> registerEmployee({
    required String fullName,
    required String area,
    required String position,
    required Gender gender,
    required DateTime entryDate,
    required DateTime birthDate,
  });

  /// Cambia el estado activo del empleado [id] y devuelve el empleado
  /// actualizado.
  ///
  /// Lanza [EmployeeNotFoundException] si el empleado no existe.
  Future<Employee> updateEmployeeStatus({
    required String id,
    required bool isActive,
  });
}
