import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/employee.dart';
import 'employee_status_control.dart';
import 'gender_label.dart';

/// Tarjeta con los datos principales de un empleado y su control de estado.
class EmployeeCard extends StatelessWidget {
  const EmployeeCard({
    super.key,
    required this.employee,
    required this.statusControlEnabled,
    required this.onStatusChanged,
  });

  final Employee employee;
  final bool statusControlEnabled;
  final ValueChanged<bool> onStatusChanged;

  static Key statusSwitchKey(String employeeId) =>
      Key('employee-status-switch-$employeeId');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _StatusBadge(isActive: employee.isActive),
                      ],
                    ),
                  ),
                ),
                EmployeeStatusControl(
                  key: statusSwitchKey(employee.id),
                  value: employee.isActive,
                  enabled: statusControlEnabled,
                  onChanged: onStatusChanged,
                  semanticLabel: 'Empleado activo: ${employee.fullName}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoItem(icon: Icons.work_outline, text: employee.position),
                  _InfoItem(
                    icon: Icons.apartment_outlined,
                    text: employee.area,
                  ),
                  _InfoItem(
                    icon: Icons.person_outline,
                    text: genderLabel(employee.gender),
                  ),
                  _InfoItem(
                    icon: Icons.event_outlined,
                    text: 'Ingreso: ${formatDate(employee.entryDate)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado del empleado mostrado con icono y texto, no solo con color.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isActive
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = isActive
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive
                  ? Icons.check_circle_outline
                  : Icons.pause_circle_outline,
              size: 16,
              color: foreground,
            ),
            const SizedBox(width: 4),
            Text(
              isActive ? 'Activo' : 'Inactivo',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
