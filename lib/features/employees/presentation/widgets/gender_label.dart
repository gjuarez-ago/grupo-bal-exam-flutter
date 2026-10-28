import '../../domain/entities/employee.dart';

/// Texto en español con el que se presenta cada [Gender].
String genderLabel(Gender gender) => switch (gender) {
  Gender.male => 'Masculino',
  Gender.female => 'Femenino',
  Gender.other => 'Otro',
};
