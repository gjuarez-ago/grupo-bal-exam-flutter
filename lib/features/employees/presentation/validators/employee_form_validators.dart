/// Reglas de validación del formulario de registro de empleados.
///
/// Son funciones puras: devuelven el mensaje de error o `null` si el valor es
/// válido. Las fechas se comparan por día y la fecha actual se recibe como
/// parámetro para que las reglas sean deterministas en las pruebas.
abstract final class EmployeeFormValidators {
  static String? fullName(String? value) =>
      _isBlank(value) ? 'Ingresa el nombre completo.' : null;

  static String? position(String? value) =>
      _isBlank(value) ? 'Ingresa el puesto.' : null;

  static String? area(String? value) =>
      value == null ? 'Selecciona un área.' : null;

  static String? gender(Object? value) =>
      value == null ? 'Selecciona un género.' : null;

  /// La fecha de entrada es obligatoria y no puede ser posterior a hoy.
  static String? entryDate(DateTime? value, {required DateTime today}) {
    if (value == null) return 'Selecciona la fecha de entrada.';
    if (_dateOnly(value).isAfter(_dateOnly(today))) {
      return 'La fecha de entrada no puede ser futura.';
    }
    return null;
  }

  /// La fecha de nacimiento es obligatoria, anterior a hoy y anterior a la
  /// fecha de entrada, si ya se eligió.
  static String? birthDate(
    DateTime? value, {
    required DateTime today,
    DateTime? entryDate,
  }) {
    if (value == null) return 'Selecciona la fecha de nacimiento.';
    final birth = _dateOnly(value);
    if (!birth.isBefore(_dateOnly(today))) {
      return 'La fecha de nacimiento debe ser anterior a hoy.';
    }
    if (entryDate != null && !birth.isBefore(_dateOnly(entryDate))) {
      return 'La fecha de nacimiento debe ser anterior a la fecha de entrada.';
    }
    return null;
  }

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
