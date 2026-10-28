import 'package:flutter/material.dart';

/// Interruptor para activar o desactivar a un empleado.
///
/// No guarda estado propio: [value] siempre proviene del estado emitido por
/// el Cubit. Con [enabled] en `false` el interruptor no responde, lo que
/// evita interacciones simultáneas mientras hay una operación en curso.
class EmployeeStatusControl extends StatelessWidget {
  const EmployeeStatusControl({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Switch(value: value, onChanged: enabled ? onChanged : null),
    );
  }
}
