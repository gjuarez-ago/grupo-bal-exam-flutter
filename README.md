# employee_management

Aplicación Flutter para la administración de empleados, desarrollada como examen técnico.

## Objetivo

Construir una aplicación de gestión de empleados organizada con Clean Architecture, manejo de estado mediante Cubit (`flutter_bloc`), datos mock y pruebas automatizadas, estructurada por módulos para que pueda crecer sin acumular archivos en carpetas globales.

## Estado actual

**Fase 2: arquitectura base.**

- Entidad de dominio `Employee` y contrato abstracto `EmployeeRepository`.
- `EmployeeState` y `EmployeeCubit`, que por ahora solo carga empleados a través del contrato.
- Tema claro con Material 3.
- Pruebas automatizadas de la entidad, el Cubit y el arranque de la app.

Todavía **no** existen la fuente de datos mock, la implementación del repositorio ni las pantallas de empleados. Al ejecutar la app solo se ve una pantalla provisional con el título.

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

# Ejecutar la aplicación
flutter run
```

## Verificación

```bash
dart format lib test
flutter analyze
flutter test
```

Pruebas disponibles:

- `test/features/employees/domain/entities/employee_test.dart`: entidad `Employee`.
- `test/features/employees/presentation/cubit/employee_cubit_test.dart`: estados de `EmployeeCubit`.
- `test/widget_test.dart`: arranque de la aplicación y tema Material 3.

## Estructura prevista

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

Consulta [docs/architecture.md](docs/architecture.md) para más detalle sobre la arquitectura prevista.
