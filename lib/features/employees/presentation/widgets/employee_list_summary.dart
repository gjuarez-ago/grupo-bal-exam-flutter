import 'package:flutter/material.dart';

/// Resumen con el total de empleados, activos e inactivos.
///
/// Recibe los totales ya calculados por el estado del Cubit.
class EmployeeListSummary extends StatelessWidget {
  const EmployeeListSummary({
    super.key,
    required this.total,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int active;
  final int inactive;

  static const totalKey = Key('employee-summary-total');
  static const activeKey = Key('employee-summary-active');
  static const inactiveKey = Key('employee-summary-inactive');

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(key: totalKey, label: 'Total', value: total),
            ),
            Expanded(
              child: _SummaryItem(
                key: activeKey,
                label: 'Activos',
                value: active,
              ),
            ),
            Expanded(
              child: _SummaryItem(
                key: inactiveKey,
                label: 'Inactivos',
                value: inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
