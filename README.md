# employee_management

Aplicación Flutter para la administración de empleados, desarrollada como examen técnico.

## Objetivo

Construir una aplicación de gestión de empleados organizada con Clean Architecture, manejo de estado mediante Cubit (`flutter_bloc`), datos mock y pruebas automatizadas, estructurada por módulos para que pueda crecer sin acumular archivos en carpetas globales.

## Estado actual

**Fase 6: integración y navegación.** La aplicación funciona de principio a fin: listado, registro con confirmación, regreso al listado actualizado y cambio de estado, sin reiniciar la aplicación.

Funcionalidades disponibles:

- **Listado de empleados:** muestra nombre, puesto, área, género, fecha de entrada (`dd/MM/yyyy`) y estado. El estado se indica con texto e icono, no solo con color.
- **Empleados inactivos atenuados:** al desactivar a un empleado, su fila cambia de aspecto (fondo más oscuro y contenido con menor opacidad) y la etiqueta pasa a «Inactivo».
- **Totales:** número total de empleados, activos e inactivos, calculados a partir de la lista actual.
- **Activar o desactivar** a un empleado con un interruptor. Si la operación falla, se muestra un mensaje y se conserva el estado real.
- **Registro de empleados** desde el botón **Nuevo empleado** (ver más abajo).
- **Estados de pantalla:** carga, lista vacía (con indicación para registrar al primer empleado) y error con botón «Reintentar».
- **Interfaz en español**, incluido el selector de fechas. Probada en pantallas pequeñas, también con el teclado abierto.
- **Prácticas de depuración** documentadas en [docs/depuracion-fase-3.md](docs/depuracion-fase-3.md), [docs/depuracion-fase-4.md](docs/depuracion-fase-4.md), [docs/depuracion-fase-5.md](docs/depuracion-fase-5.md) y [docs/depuracion-fase-6.md](docs/depuracion-fase-6.md).

## Registro de empleados

1. En la pantalla **Empleados**, pulsa **Nuevo empleado**. Pulsarlo varias veces seguidas abre un solo formulario.
2. Completa el formulario **Registrar empleado**:
   - **Nombre completo** y **Puesto**: obligatorios. Se ignoran los espacios al inicio y al final.
   - **Área**: se elige de una lista (Administración, Finanzas, Operaciones, Recursos Humanos, Tecnología, Ventas).
   - **Género**: se elige de una lista (Masculino, Femenino, Otro).
   - **Fecha de entrada**: se elige en un calendario (no se puede escribir a mano) y no puede ser futura.
   - **Fecha de nacimiento**: se elige en un calendario y debe ser anterior a hoy y a la fecha de entrada.
3. Pulsa **Registrar empleado**.
   - Si falta algún dato, el formulario muestra el error junto al campo y no registra nada.
   - Mientras se registra, el botón muestra «Registrando…» y no acepta pulsaciones repetidas.
4. Si el registro termina bien, aparece la pantalla **Empleado registrado correctamente**. Con **Regresar a empleados** vuelves a la lista, donde ya aparece el nuevo empleado (activo) y los totales están actualizados.
5. Si el registro falla, se muestra el mensaje de error, los datos capturados se conservan y puedes reintentar.
6. **Cancelar** vuelve al listado sin registrar a nadie.

## Cómo se comparte el estado entre pantallas

- Hay **una sola instancia** de `EmployeeCubit` durante la sesión. Se crea en `app.dart`, por encima de `MaterialApp`, y la usan el listado, el formulario y la confirmación.
- El formulario registra a través de ese Cubit. Al volver al listado, la lista y los totales ya están actualizados, sin recargar ni reiniciar.
- Los cambios de estado activo/inactivo también viven en el Cubit, así que se conservan al ir y volver del formulario.
- Las pantallas no guardan copias de la lista. Los datos iniciales solo se cargan al arrancar, así que volver al listado no sobrescribe los cambios de la sesión.
- La confirmación de éxito depende del resultado real del registro. Si el repositorio falla, no se muestra y el empleado no se agrega.

## Persistencia y sus limitaciones

Los empleados se guardan **solo en memoria** (`EmployeeLocalDataSource`), que arranca con cinco empleados ficticios:

- Los registros y los cambios de estado se conservan mientras la aplicación siga abierta.
- **Se pierden al cerrar o reiniciar la aplicación.** No hay base de datos ni API.
- Los datos no se comparten entre dispositivos.

## Arquitectura

Clean Architecture por funcionalidades, con Cubit para el estado:

```text
EmployeesPage / EmployeeFormPage  (presentación)
        |
        v
EmployeeCubit                     (estado)
        |
        v
EmployeeRepository                (contrato de dominio)
        ^
        |
EmployeeRepositoryImpl            (datos)
        |
        v
EmployeeLocalDataSource           (memoria)
```

La inyección de dependencias es manual: `main.dart` crea la fuente de datos y el repositorio, y `app.dart` los provee junto con una única instancia de `EmployeeCubit`. Consulta [docs/architecture.md](docs/architecture.md) para el detalle.

## Dependencias

| Paquete | Versión | Uso |
|---|---|---|
| `flutter_bloc` | ^9.1.1 | Gestión de estado con Cubit |
| `equatable` | ^3.0.0 | Igualdad por valor en entidades y estados |
| `flutter_localizations` | SDK de Flutter | Textos de Material y selector de fechas en español |
| `bloc_test` (dev) | ^10.0.0 | Pruebas de transiciones del Cubit |
| `mocktail` (dev) | ^1.0.5 | Simulación del repositorio y del Cubit en pruebas |

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

## Pruebas y verificación

```bash
dart format lib test
flutter analyze
flutter test
```

Para ejecutar un solo archivo de pruebas:

```bash
flutter test test/features/employees/presentation/pages/employee_form_page_test.dart
```

Pruebas disponibles (105 en total):

- `test/core/utils/date_formatter_test.dart`: formato de fechas.
- `test/features/employees/domain/entities/employee_test.dart`: entidad `Employee`.
- `test/features/employees/data/datasources/employee_local_data_source_test.dart`: fuente de datos en memoria.
- `test/features/employees/data/repositories/employee_repository_impl_test.dart`: repositorio concreto.
- `test/features/employees/presentation/cubit/employee_cubit_test.dart`: estados de `EmployeeCubit`, incluido el registro con el repositorio en memoria.
- `test/features/employees/presentation/cubit/employee_state_test.dart`: totales de activos e inactivos.
- `test/features/employees/presentation/validators/employee_form_validators_test.dart`: reglas de validación del formulario.
- `test/features/employees/presentation/widgets/employee_card_test.dart`: tarjeta de empleado.
- `test/features/employees/presentation/pages/employees_page_test.dart`: pantalla de listado.
- `test/features/employees/presentation/pages/employee_form_page_test.dart`: formulario de registro.
- `test/features/employees/employee_registration_flow_test.dart`: flujo completo listado → registro → listado.
- `test/app_flow_test.dart`: aplicación completa (navegación, estado compartido entre pantallas, errores y pantallas pequeñas).
- `test/widget_test.dart`: arranque, tema Material 3 y carga de empleados.

## Estructura

```text
lib/
├── core/            # Recursos transversales (tema, formato de fechas)
├── shared/          # Componentes compartidos entre módulos (widgets)
├── features/
│   └── employees/   # Módulo de empleados
│       ├── domain/        # Entidades, catálogo de áreas y contrato de repositorio
│       ├── data/          # Fuente de datos en memoria e implementación del repositorio
│       └── presentation/  # Cubit, páginas, widgets y validaciones del formulario
├── app.dart         # Widget raíz: tema, idioma y proveedores
└── main.dart        # Punto de entrada y composición de dependencias
```

Las carpetas aún vacías (`shared/widgets`) contienen un archivo `.gitkeep` para que Git las conserve.
