# Arquitectura

> **Estado:** Fase 4 (listado de empleados). La pantalla `EmployeesPage` muestra la lista, los totales y permite activar o desactivar empleados a través del Cubit, con datos ficticios en memoria. Todavía **no** existe el formulario de registro: `registerEmployee` está disponible en el Cubit pero ninguna pantalla lo usa.

## Enfoque

El proyecto sigue Clean Architecture organizada por funcionalidades (*features*). Cada módulo agrupa sus propias capas, de modo que el código de una funcionalidad vive junto y no se dispersa en carpetas globales.

## Flujo

```text
EmployeesPage (EmployeeListSummary, EmployeeCard, EmployeeStatusControl)
    |
    v
EmployeeCubit
    |
    v
EmployeeRepository (contrato de dominio)
    ^
    |
EmployeeRepositoryImpl
    |
    v
EmployeeLocalDataSource
    |
    v
Datos ficticios en memoria (employeeMockData)
```

## Dependencias permitidas entre capas

| Capa | Puede depender de | No puede depender de |
|---|---|---|
| `domain` | Dart puro y `equatable` | Flutter, `flutter_bloc`, `data`, `presentation` |
| `data` | `domain` | `presentation`, Flutter |
| `presentation` | `domain`, Flutter, `flutter_bloc` | Implementaciones de `data` |

Solo el punto de composición (`main.dart`) conoce las implementaciones concretas.

El dominio no depende de Flutter ni de la implementación de datos porque contiene las reglas de negocio. Así puede probarse sin interfaz, y la fuente de datos (mock, red o almacenamiento local) puede sustituirse sin modificar el dominio ni la presentación.

## Dominio

### Entidad `Employee`

`lib/features/employees/domain/entities/employee.dart`

Representa a un empleado ya registrado. Todos sus campos son obligatorios:

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `String` | Identificador único asignado por la capa de datos |
| `fullName` | `String` | Nombre completo |
| `area` | `String` | Área de trabajo |
| `position` | `String` | Puesto |
| `gender` | `Gender` | Enumeración `male` / `female` |
| `entryDate` | `DateTime` | Fecha de ingreso |
| `birthDate` | `DateTime` | Fecha de nacimiento |
| `isActive` | `bool` | Estado activo |

- Usa `equatable` para comparar por valor.
- `copyWith` crea copias modificadas sin mutar la instancia original y conserva siempre el `id`.

### Contrato `EmployeeRepository`

`lib/features/employees/domain/repositories/employee_repository.dart`

- `getEmployees()`: devuelve todos los empleados. Una lista vacía es un resultado válido.
- `registerEmployee(...)`: recibe los datos sin `id` ni `isActive`. La implementación asigna el `id`, registra al empleado como activo y lo devuelve.
- `updateEmployeeStatus(id:, isActive:)`: devuelve el empleado actualizado.

**Errores:** las implementaciones lanzan `EmployeeRepositoryException` ante fallos esperados, y `EmployeeNotFoundException` cuando el `id` no existe.

## Datos

### `EmployeeLocalDataSource`

`lib/features/employees/data/datasources/employee_local_data_source.dart`

Guarda los empleados en una lista privada en memoria. Por defecto arranca con los cinco empleados de `employeeMockData`; también acepta una lista inicial distinta (por ejemplo, vacía para las pruebas).

- **Sin colecciones mutables expuestas:** `getEmployees()` devuelve una copia no modificable.
- **Identificadores únicos:** se generan como `emp-N` con un contador interno, saltando cualquier id que ya exista.
- **Actualización:** localiza al empleado por `id` y reemplaza solo esa posición con `copyWith`. Si el id no existe lanza `EmployeeNotFoundException` y no modifica nada.

### `EmployeeRepositoryImpl`

`lib/features/employees/data/repositories/employee_repository_impl.dart`

Implementa el contrato y delega cada operación en la fuente local. Sus métodos son `async`, de modo que las excepciones de la fuente llegan al llamador como un `Future` fallido, igual que ocurriría con una fuente remota.

No se creó un modelo de datos separado (`EmployeeModel`) porque la fuente en memoria no serializa. Se incorporará si se agrega una API o almacenamiento persistente.

### Limitaciones del almacenamiento en memoria

- Los datos se pierden al reiniciar la aplicación. Cada arranque vuelve a los cinco empleados ficticios.
- Los datos no se comparten entre dispositivos ni entre instancias de la aplicación.
- Las operaciones no tienen latencia real, así que el estado `loading` es prácticamente instantáneo.

## Presentación

### `EmployeeState`

`lib/features/employees/presentation/cubit/employee_state.dart`

Es una única clase inmutable con:

- `status`: `initial`, `loading`, `success` o `failure`.
- `employees`: lista no modificable.
- `errorMessage`: solo tiene valor cuando `status` es `failure`.
- `totalCount`, `activeCount` e `inactiveCount`: totales **derivados** de `employees`. No se almacenan por separado, así que no pueden quedar desincronizados de la lista.

### `EmployeeCubit`

`lib/features/employees/presentation/cubit/employee_cubit.dart`

Recibe `EmployeeRepository` por constructor. Todas las operaciones emiten `loading` y después `success` o `failure`:

| Método | En éxito | Devuelve |
|---|---|---|
| `loadEmployees()` | Reemplaza la lista con la del repositorio | — |
| `registerEmployee(...)` | Agrega el empleado nuevo al final de la lista actual | `true` / `false` |
| `updateEmployeeStatus(id:, isActive:)` | Reemplaza solo el empleado afectado | `true` / `false` |

En caso de fallo:

- Se conserva la lista vigente, de modo que el Cubit puede seguir usándose.
- Una `EmployeeRepositoryException` muestra su mensaje.
- Cualquier otro error se reporta con `addError` y se muestra un mensaje genérico.
- Un fallo nunca se presenta como éxito.

### Pantalla `EmployeesPage`

`lib/features/employees/presentation/pages/employees_page.dart`

Toma el `EmployeeCubit` del árbol con `BlocConsumer` y no crea instancias propias. La carga inicial no se repite al reconstruir: la dispara `app.dart` al crear el Cubit.

La vista se decide así:

| Situación | Vista |
|---|---|
| Hay empleados en la lista | Resumen de totales y tarjetas (`ListView.separated`) |
| Lista vacía e `initial` / `loading` | Indicador de progreso |
| Lista vacía y `success` | «Todavía no hay empleados registrados.» |
| Lista vacía y `failure` | «No se pudieron cargar los empleados.», el mensaje y «Reintentar» (`loadEmployees`) |

Comportamiento con datos en pantalla:

- **Fallo de una operación** (por ejemplo, al cambiar un estado): se informa con un `SnackBar` y la lista sigue mostrando el estado real del Cubit.
- **Operación en curso** (`status == loading`): los interruptores se deshabilitan para evitar cambios simultáneos.

Widgets de apoyo, en `presentation/widgets/`:

- `EmployeeCard`:
  - muestra nombre (elemento principal), puesto, área, género y fecha de ingreso (`dd/MM/yyyy`);
  - muestra el estado con icono **y** texto («Activo» / «Inactivo»), no solo con color;
  - incluye el interruptor.
- `EmployeeStatusControl`: un `Switch` sin estado propio; su valor siempre proviene de `employee.isActive`.
- `EmployeeListSummary`: muestra los totales que recibe del estado.

La fecha se formatea con `formatDate` (`lib/core/utils/date_formatter.dart`), en Dart puro, sin agregar `intl`. La entidad conserva el `DateTime` original.

## Inyección de dependencias

Es manual y no usa ningún contenedor externo, porque solo hay una dependencia:

1. `main.dart` crea `EmployeeLocalDataSource` y `EmployeeRepositoryImpl`.
2. Pasa el repositorio a `EmployeeManagementApp`, que solo conoce el contrato `EmployeeRepository`.
3. `app.dart` lo expone con `RepositoryProvider` y crea `EmployeeCubit` con `BlocProvider`, que llama a `loadEmployees()` al crearlo.

Para las pruebas basta con pasar otra implementación del contrato a `EmployeeManagementApp`.

## Pruebas

| Archivo | Qué cubre |
|---|---|
| `domain/entities/employee_test.dart` | Construcción, igualdad y `copyWith` |
| `data/datasources/employee_local_data_source_test.dart` | Datos ficticios, lista vacía, inmutabilidad, ids únicos, registro, actualización aislada, id inexistente |
| `data/repositories/employee_repository_impl_test.dart` | Delegación de las tres operaciones y propagación de errores |
| `presentation/cubit/employee_cubit_test.dart` | Secuencias de estados de carga, registro y actualización, en éxito y en fallo, y recuperación tras un fallo |
| `presentation/cubit/employee_state_test.dart` | Totales de activos e inactivos |
| `presentation/widgets/employee_card_test.dart` | Datos de la tarjeta, estado con texto e interruptor, interruptor deshabilitado |
| `presentation/pages/employees_page_test.dart` | Carga, lista, lista vacía, error con reintento, totales, pantallas pequeñas e interacción con el Cubit real |
| `test/core/utils/date_formatter_test.dart` | Formato `dd/MM/yyyy` |
| `test/widget_test.dart` | Arranque, Material 3 y carga de los empleados ficticios |

Salvo las dos últimas filas, las rutas son relativas a `test/features/employees/`.

Las pruebas de la página siguen dos estrategias:

- Un `MockCubit` (`bloc_test`) para fijar cada estado de presentación.
- El `EmployeeCubit` real con un repositorio simulado (`mocktail`) para verificar que la interfaz reacciona a los estados que emite.

Los defectos intencionales están documentados en [depuracion-fase-3.md](depuracion-fase-3.md) y [depuracion-fase-4.md](depuracion-fase-4.md).

## Pendiente para la Fase 5

- Formulario de registro de empleados, con validaciones.
- Selectores de fecha de ingreso y de nacimiento.
