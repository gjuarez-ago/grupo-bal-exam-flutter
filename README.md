# employee_management

Aplicación Flutter para la administración de empleados, desarrollada como examen técnico.

## Objetivo

Construir una aplicación de gestión de empleados organizada con Clean Architecture, manejo de estado mediante Cubit (`flutter_bloc`), datos mock y pruebas automatizadas, estructurada por módulos para que pueda crecer sin acumular archivos en carpetas globales.

## Estado actual

**Fase 3: capa de datos.**

- Fuente de datos local en memoria con cinco empleados ficticios (`EmployeeLocalDataSource`).
- Repositorio concreto `EmployeeRepositoryImpl`, que implementa el contrato del dominio.
- `EmployeeCubit` carga, registra y cambia el estado activo de los empleados.
- Inyección manual de dependencias en `main.dart` y `app.dart`.
- Práctica de depuración con tres errores intencionales, documentada en [docs/depuracion-fase-3.md](docs/depuracion-fase-3.md).

Los datos se guardan en memoria y **se pierden al reiniciar la aplicación**. Todavía no existen el listado definitivo ni el formulario de registro: al ejecutar la app se ve una pantalla provisional que indica cuántos empleados se cargaron.

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

Pruebas disponibles (31 en total):

- `test/features/employees/domain/entities/employee_test.dart`: entidad `Employee`.
- `test/features/employees/data/datasources/employee_local_data_source_test.dart`: fuente de datos en memoria.
- `test/features/employees/data/repositories/employee_repository_impl_test.dart`: repositorio concreto.
- `test/features/employees/presentation/cubit/employee_cubit_test.dart`: estados de `EmployeeCubit`.
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
