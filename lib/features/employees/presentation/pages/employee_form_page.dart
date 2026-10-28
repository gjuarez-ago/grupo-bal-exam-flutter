import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_areas.dart';
import '../cubit/employee_cubit.dart';
import '../validators/employee_form_validators.dart';
import '../widgets/gender_label.dart';
import 'employee_registration_success_page.dart';

/// Formulario para registrar un empleado nuevo.
///
/// Valida los datos antes de llamar al [EmployeeCubit]. Solo guarda el estado
/// propio del formulario (valores capturados y envío en curso); la lista de
/// empleados vive únicamente en el Cubit.
class EmployeeFormPage extends StatefulWidget {
  const EmployeeFormPage({super.key, this.today});

  /// Fecha de referencia para las validaciones. Por defecto, la fecha actual;
  /// las pruebas la fijan para ser deterministas.
  final DateTime? today;

  static const fullNameKey = Key('employee-form-full-name');
  static const positionKey = Key('employee-form-position');
  static const areaKey = Key('employee-form-area');
  static const genderKey = Key('employee-form-gender');
  static const entryDateKey = Key('employee-form-entry-date');
  static const birthDateKey = Key('employee-form-birth-date');
  static const submitErrorKey = Key('employee-form-submit-error');

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _positionController = TextEditingController();
  late final DateTime _today = DateUtils.dateOnly(
    widget.today ?? DateTime.now(),
  );

  String? _area;
  Gender? _gender;
  DateTime? _entryDate;
  DateTime? _birthDate;
  bool _isSubmitting = false;
  String? _submitError;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _fullNameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _submitError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final cubit = context.read<EmployeeCubit>();
    final fullName = _fullNameController.text.trim();
    final registered = await cubit.registerEmployee(
      fullName: fullName,
      area: _area!,
      position: _positionController.text.trim(),
      gender: _gender!,
      entryDate: _entryDate!,
      birthDate: _birthDate!,
    );
    if (!mounted) return;

    if (registered) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              EmployeeRegistrationSuccessPage(employeeName: fullName),
        ),
      );
    } else {
      // Se conservan los datos capturados para que el usuario reintente.
      setState(() {
        _isSubmitting = false;
        _submitError =
            cubit.state.errorMessage ?? EmployeeCubit.unexpectedErrorMessage;
      });
    }
  }

  Future<DateTime?> _pickEntryDate() {
    // No se permite ingresar antes de nacer ni en el futuro.
    final firstDate = _birthDate == null
        ? DateTime(1900)
        : _nextDay(_birthDate!);
    return _showPicker(
      helpText: 'Fecha de ingreso',
      initialDate: _entryDate ?? _today,
      firstDate: firstDate,
      lastDate: _today,
    );
  }

  Future<DateTime?> _pickBirthDate() {
    // Debe ser anterior a hoy y a la fecha de ingreso, si ya se eligió.
    final lastDate = _previousDay(_entryDate ?? _today);
    return _showPicker(
      helpText: 'Fecha de nacimiento',
      initialDate:
          _birthDate ?? DateTime(_today.year - 30, _today.month, _today.day),
      firstDate: DateTime(1900),
      lastDate: lastDate,
    );
  }

  Future<DateTime?> _showPicker({
    required String helpText,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final clamped = initialDate.isBefore(firstDate)
        ? firstDate
        : initialDate.isAfter(lastDate)
        ? lastDate
        : initialDate;
    return showDatePicker(
      context: context,
      initialDate: clamped,
      firstDate: firstDate,
      lastDate: lastDate,
      // Solo calendario: el usuario no puede escribir la fecha a mano.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: helpText,
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
  }

  static DateTime _nextDay(DateTime date) =>
      DateTime(date.year, date.month, date.day + 1);

  static DateTime _previousDay(DateTime date) =>
      DateTime(date.year, date.month, date.day - 1);

  @override
  Widget build(BuildContext context) {
    final enabled = !_isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar empleado')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Completa los datos del nuevo empleado. Se registrará como '
                'activo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: EmployeeFormPage.fullNameKey,
                controller: _fullNameController,
                enabled: enabled,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: EmployeeFormValidators.fullName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: EmployeeFormPage.positionKey,
                controller: _positionController,
                enabled: enabled,
                decoration: const InputDecoration(labelText: 'Puesto'),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                validator: EmployeeFormValidators.position,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: EmployeeFormPage.areaKey,
                initialValue: _area,
                // Ocupa el ancho disponible y recorta opciones largas en
                // pantallas estrechas en lugar de desbordarse.
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Área'),
                items: [
                  for (final area in employeeAreas)
                    DropdownMenuItem(value: area, child: Text(area)),
                ],
                onChanged: enabled
                    ? (value) => setState(() => _area = value)
                    : null,
                validator: EmployeeFormValidators.area,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Gender>(
                key: EmployeeFormPage.genderKey,
                initialValue: _gender,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Género'),
                items: [
                  for (final gender in Gender.values)
                    DropdownMenuItem(
                      value: gender,
                      child: Text(genderLabel(gender)),
                    ),
                ],
                onChanged: enabled
                    ? (value) => setState(() => _gender = value)
                    : null,
                validator: EmployeeFormValidators.gender,
              ),
              const SizedBox(height: 16),
              _DateFormField(
                key: EmployeeFormPage.entryDateKey,
                label: 'Fecha de ingreso',
                value: _entryDate,
                enabled: enabled,
                onPick: _pickEntryDate,
                onChanged: (date) => setState(() => _entryDate = date),
                validator: () =>
                    EmployeeFormValidators.entryDate(_entryDate, today: _today),
              ),
              const SizedBox(height: 16),
              _DateFormField(
                key: EmployeeFormPage.birthDateKey,
                label: 'Fecha de nacimiento',
                value: _birthDate,
                enabled: enabled,
                onPick: _pickBirthDate,
                onChanged: (date) => setState(() => _birthDate = date),
                validator: () => EmployeeFormValidators.birthDate(
                  _birthDate,
                  today: _today,
                  entryDate: _entryDate,
                ),
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 20),
                _SubmitError(
                  key: EmployeeFormPage.submitErrorKey,
                  message: _submitError!,
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: enabled ? _submit : null,
                child: _isSubmitting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Registrando…'),
                        ],
                      )
                    : const Text('Registrar empleado'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: enabled ? () => Navigator.of(context).pop() : null,
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de formulario que abre un selector de fecha al pulsarlo.
class _DateFormField extends StatelessWidget {
  const _DateFormField({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPick,
    required this.onChanged,
    required this.validator,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final Future<DateTime?> Function() onPick;
  final ValueChanged<DateTime> onChanged;
  final String? Function() validator;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      validator: (_) => validator(),
      builder: (field) => InkWell(
        onTap: enabled
            ? () async {
                final picked = await onPick();
                if (picked == null) return;
                onChanged(picked);
                field.didChange(picked);
              }
            : null,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            enabled: enabled,
            errorText: field.errorText,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(value == null ? '' : formatDate(value!)),
        ),
      ),
    );
  }
}

class _SubmitError extends StatelessWidget {
  const _SubmitError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
