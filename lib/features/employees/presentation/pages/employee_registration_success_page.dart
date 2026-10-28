import 'package:flutter/material.dart';

/// Confirmación que se muestra solo después de que el registro terminó bien.
class EmployeeRegistrationSuccessPage extends StatelessWidget {
  const EmployeeRegistrationSuccessPage({
    super.key,
    required this.employeeName,
  });

  final String employeeName;

  static const title = 'Empleado registrado correctamente';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$employeeName ya aparece en la lista de empleados.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Regresar a empleados'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
