import 'package:flutter/material.dart';

import 'app.dart';
import 'features/employees/data/datasources/employee_local_data_source.dart';
import 'features/employees/data/repositories/employee_repository_impl.dart';

/// Punto de composición: aquí se eligen las implementaciones concretas.
void main() {
  final employeeRepository = EmployeeRepositoryImpl(EmployeeLocalDataSource());

  runApp(EmployeeManagementApp(employeeRepository: employeeRepository));
}
