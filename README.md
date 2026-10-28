# employee_management

Aplicación Flutter para la administración de empleados, desarrollada como examen técnico.

## Objetivo

Construir una aplicación de gestión de empleados organizada con Clean Architecture, manejo de estado mediante Cubit (`flutter_bloc`), datos mock y pruebas automatizadas, estructurada por módulos para que pueda crecer sin acumular archivos en carpetas globales.

## Estado actual

**Fase 4: listado de empleados.**

Funcionalidades disponibles:

- **Listado de empleados:** muestra nombre, puesto, área, género, fecha de ingreso (`dd/MM/yyyy`) y estado. El estado se indica con texto e icono, no solo con color.
- **Totales:** número total de empleados, activos e inactivos, calculados a partir de la lista actual.
- **Activar o desactivar** a un empleado con un interruptor. La lista y los totales se actualizan con el estado que emite el Cubit. Si la operación falla, se muestra un mensaje y se conserva el estado real.
- **Estados de pantalla:** carga, lista vacía («Todavía no hay empleados registrados.») y error con botón «Reintentar».
- **Arquitectura:**
  - fuente de datos en memoria con cinco empleados ficticios;
  - repositorio concreto `EmployeeRepositoryImpl`;
  - `EmployeeCubit`;
  - inyección manual de dependencias en `main.dart` y `app.dart`.
- **Prácticas de depuración** documentadas en [docs/depuracion-fase-3.md](docs/depuracion-fase-3.md) y [docs/depuracion-fase-4.md](docs/depuracion-fase-4.md).

Limitaciones:

- Los datos se guardan en memoria y **se pierden al reiniciar la aplicación**.
- Todavía **no** existe el formulario de registro de empleados (Fase 5).

## Dependencias

| Paquete | Versión | Uso |
|---|---|---|
| `flutter_bloc` | ^9.1.1 | Gestión de estado con Cubit |
| `equatable` | ^3.0.0 | Igualdad por valor en entidades y estados |
| `bloc_test` (dev) | ^10.0.0 | Pruebas de transiciones del Cubit |
| `mocktail` (dev) | ^1.0.5 | Simulación del contrato del repositorio en pruebas |

## Requisitos previos

- Flutter SDK (canal stable) — versión utilizada: **Flutter 3.41.6**
- Dart SDK — versión utilizada: **Dart 3.11.4**
- Git
- Un emulador, dispositivo físico o navegador compatible con Flutter

Comprueba tu entorno con:

```bash
flutter doctor
```

## Instalación y ejecución

```bash
# Instalar dependencias
flutter pub get

# Ejecutar la aplicación (elige un dispositivo con `flutter devices`)
flutter run
# Por ejemplo, en el navegador:
flutter run -d chrome
```

## Verificación

```bash
dart format lib test
flutter analyze
flutter test
```

Para ejecutar un solo archivo de pruebas:

```bash
flutter test test/features/employees/presentation/cubit/employee_cubit_test.dart
```

Pruebas disponibles (57 en total):

- `test/core/utils/date_formatter_test.dart`: formato de fechas.
- `test/features/employees/domain/entities/employee_test.dart`: entidad `Employee`.
- `test/features/employees/data/datasources/employee_local_data_source_test.dart`: fuente de datos en memoria.
- `test/features/employees/data/repositories/employee_repository_impl_test.dart`: repositorio concreto.
- `test/features/employees/presentation/cubit/employee_cubit_test.dart`: estados de `EmployeeCubit`.
- `test/features/employees/presentation/cubit/employee_state_test.dart`: totales de activos e inactivos.
- `test/features/employees/presentation/widgets/employee_card_test.dart`: tarjeta de empleado.
- `test/features/employees/presentation/pages/employees_page_test.dart`: pantalla de listado (presentación e interacción).
- `test/widget_test.dart`: arranque, tema Material 3 y carga de empleados.

## Estructura

```text
lib/
├── core/            # Recursos transversales (tema, utilidades)
├── shared/          # Componentes compartidos entre módulos (widgets)
├── features/
│   └── employees/   # Módulo de empleados
│       ├── domain/        # Entidades y contratos de repositorio
│       ├── data/          # Fuentes de datos e implementaciones de repositorio
│       └── presentation/  # Cubit, páginas y widgets
├── app.dart         # Widget raíz de la aplicación
└── main.dart        # Punto de entrada
```

Las carpetas vacías contienen un archivo `.gitkeep` para que Git las conserve; se eliminará cuando la carpeta tenga contenido real.

Consulta [docs/architecture.md](docs/architecture.md) para más detalle sobre la arquitectura.
