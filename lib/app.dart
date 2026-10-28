import 'package:flutter/material.dart';

/// Widget raíz de la aplicación.
///
/// Configuración mínima de arranque. El tema definitivo y las pantallas de
/// empleados se incorporarán en fases posteriores.
class EmployeeManagementApp extends StatelessWidget {
  const EmployeeManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de empleados',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.indigo)),
      home: const Scaffold(body: Center(child: Text('Gestión de empleados'))),
    );
  }
}
