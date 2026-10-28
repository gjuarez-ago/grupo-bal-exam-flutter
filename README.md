# Gestión de empleados — Examen técnico Flutter

Aplicación Flutter para registrar y administrar empleados. Usa Clean Architecture, Cubit (`flutter_bloc`) y datos mock locales; no consume ninguna API ni base de datos.

## Funcionalidad

**Lista de empleados (pantalla principal)**

- Muestra nombre completo, área, puesto, género, fecha de entrada y estado (Activo / Inactivo).
- Cada empleado tiene un `Switch` para activarlo o desactivarlo. Al desactivarlo, el estado cambia a «Inactivo» y la fila se muestra atenuada (fondo más oscuro y menor opacidad).
- Encabezado con el total de empleados, activos e inactivos.
- Botón **Nuevo empleado** para abrir el registro.

**Registro de empleado**

| Campo | Componente | Regla |
|---|---|---|
| Nombre completo | Campo de texto | Obligatorio |
| Área | `DropdownButtonFormField` | Obligatoria: Tecnología, Recursos Humanos, Finanzas, Operaciones, Ventas, Administración |
| Fecha de entrada | `DatePicker` (solo calendario) | Obligatoria; no puede ser futura; no se escribe a mano |
| Puesto | Campo de texto | Obligatorio |
| Género | `DropdownButtonFormField` | Obligatorio: Masculino, Femenino, Otro |
| Fecha de nacimiento | `DatePicker` (solo calendario) | Obligatoria; anterior a hoy y a la fecha de entrada |

Al pulsar **Registrar empleado** se validan los campos, se crea el empleado (activo) y se guarda en el origen de datos mock local. Si todo sale bien se muestra la pantalla **Empleado registrado correctamente**, con el botón **Regresar a empleados**; al volver, el empleado nuevo aparece en la lista y los totales se actualizan.

Si algo falla, el formulario muestra el error, conserva los datos capturados y permite reintentar.

## Requisitos

- Flutter **3.41.6** (canal stable)
- Dart **3.11.4**
- Un emulador, dispositivo o navegador compatible (`flutter devices`)

## Ejecución

```bash
flutter pub get
flutter run
```

Para elegir un dispositivo, por ejemplo el navegador:

```bash
flutter run -d chrome
```

## Pruebas

```bash
flutter analyze
flutter test
```

Hay 105 pruebas unitarias y de widgets: entidad, fuente de datos, repositorio, Cubit, validaciones, tarjeta de empleado, pantallas y el flujo completo listado → registro → confirmación → listado.

## Arquitectura

Clean Architecture organizada por funcionalidad (`features/employees`), con tres capas:

- **Dominio:** la entidad `Employee` y el contrato abstracto `EmployeeRepository`. No depende de Flutter ni de la capa de datos.
- **Datos:** `EmployeeLocalDataSource` guarda los empleados en memoria (arranca con cinco empleados de ejemplo) y `EmployeeRepositoryImpl` implementa el contrato.
- **Presentación:** `EmployeeCubit` y su estado, las pantallas (listado, formulario y confirmación) y sus widgets.

```text
Pantallas ──► EmployeeCubit ──► EmployeeRepository (contrato)
                                        ▲
                                        │
                              EmployeeRepositoryImpl ──► EmployeeLocalDataSource (memoria)
```

Las dependencias se crean a mano en `main.dart` y se proveen en `app.dart` con `RepositoryProvider` y `BlocProvider`. Hay una sola instancia de `EmployeeCubit` para toda la app, por lo que el listado y el formulario comparten el mismo estado y los cambios se ven al regresar sin recargar.

```text
lib/
├── core/                  # Tema y utilidades (formato de fechas)
├── features/employees/
│   ├── domain/            # Entidades, catálogo de áreas y contrato del repositorio
│   ├── data/              # Fuente de datos mock e implementación del repositorio
│   └── presentation/      # Cubit, páginas, widgets y validaciones
├── app.dart               # Tema, idioma y proveedores
└── main.dart              # Punto de entrada
```

Más detalle en [docs/architecture.md](docs/architecture.md).

## Dependencias principales

| Paquete | Uso |
|---|---|
| `flutter_bloc` ^9.1.1 | Gestión de estado con Cubit |
| `equatable` ^3.0.0 | Comparación por valor de entidades y estados |
| `flutter_localizations` (SDK) | Interfaz y calendario en español |
| `bloc_test` ^10.0.0 (dev) | Pruebas del Cubit |
| `mocktail` ^1.0.5 (dev) | Dobles de prueba |

## Notas

- Los datos viven solo en memoria: los registros y cambios de estado se conservan mientras la app está abierta y se pierden al cerrarla.
- El formato de fecha es `dd/MM/yyyy`.
