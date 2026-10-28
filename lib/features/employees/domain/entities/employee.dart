import 'package:equatable/equatable.dart';

/// Género del empleado.
enum Gender { male, female }

/// Entidad de dominio que representa a un empleado.
///
/// Es independiente de Flutter y de cualquier fuente de datos. Todos los
/// campos son obligatorios: una instancia de [Employee] siempre representa a un
/// empleado ya registrado, por lo que tiene un [id] asignado por la capa de
/// datos.
class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.fullName,
    required this.area,
    required this.position,
    required this.gender,
    required this.entryDate,
    required this.birthDate,
    required this.isActive,
  });

  /// Identificador único asignado al registrar al empleado.
  final String id;
  final String fullName;
  final String area;
  final String position;
  final Gender gender;

  /// Fecha de ingreso a la empresa.
  final DateTime entryDate;
  final DateTime birthDate;

  /// Indica si el empleado está activo.
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    fullName,
    area,
    position,
    gender,
    entryDate,
    birthDate,
    isActive,
  ];
}
