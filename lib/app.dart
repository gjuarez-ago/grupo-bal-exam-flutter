import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

/// Widget raíz de la aplicación.
///
/// Las pantallas de empleados y la inyección del repositorio se incorporarán
/// en la Fase 3.
class EmployeeManagementApp extends StatelessWidget {
  const EmployeeManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de empleados',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(body: Center(child: Text('Gestión de empleados'))),
    );
  }
}
