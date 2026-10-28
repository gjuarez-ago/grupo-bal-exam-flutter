/// Formatea [date] como `dd/MM/yyyy`, por ejemplo `27/10/2026`.
///
/// Solo presenta la fecha; no modifica el valor original.
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}
