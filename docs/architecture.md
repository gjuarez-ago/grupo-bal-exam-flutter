# Arquitectura

> **Estado:** Fase 6 (integración y navegación). El flujo completo funciona de principio a fin: listado, registro con confirmación, regreso al listado actualizado y cambio de estado. Todas las pantallas comparten un único `EmployeeCubit` durante la sesión. Los datos viven en memoria y se pierden al cerrar o reiniciar la aplicación.

## Enfoque

El proyecto sigue Clean Architecture organizada por funcionalidades (*features*). Cada módulo agrupa sus propias capas, de modo que el código de una funcionalidad vive junto y no se dispersa en carpetas globales.

## Flujo

```text
EmployeesPage (listado)  ──►  EmployeeFormPage (registro)  ──►  EmployeeRegistrationSuccessPage
    |                               |
    v                               v
EmployeeCubit (instancia única, compartida por ambas pantallas)
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

- **Fallo de una operación** (por ejemplo, al cambiar un estado): se informa con un `SnackBar` y la lista sigue mostrando el estado real del Cubit. El `SnackBar` solo aparece si el listado es la ruta visible (`ModalRoute.isCurrent`). Si el fallo ocurre mientras el formulario está abierto, lo informa el formulario y el mensaje no se duplica.
- **Operación en curso** (`status == loading`): los interruptores se deshabilitan para evitar cambios simultáneos.

Widgets de apoyo, en `presentation/widgets/`:

- `EmployeeCard`:
  - muestra nombre (elemento principal), puesto, área, género y fecha de ingreso (`dd/MM/yyyy`);
  - muestra el estado con icono **y** texto («Activo» / «Inactivo»), no solo con color;
  - incluye el interruptor.
- `EmployeeStatusControl`: un `Switch` sin estado propio; su valor siempre proviene de `employee.isActive`.
- `EmployeeListSummary`: muestra los totales que recibe del estado.

La fecha se formatea con `formatDate` (`lib/core/utils/date_formatter.dart`), en Dart puro. La entidad conserva el `DateTime` original.

El botón flotante **Nuevo empleado** abre el formulario de registro con `Navigator.push`. Ignora pulsaciones mientras el formulario está abierto, así que no se apilan formularios duplicados.

El estado vacío explica cómo registrar al primer empleado: «Pulsa «Nuevo empleado» para registrar al primero.».

### Registro: `EmployeeFormPage`

`lib/features/employees/presentation/pages/employee_form_page.dart`

```text
EmployeeFormPage
    | 1. Form.validate() con EmployeeFormValidators (antes de llamar al Cubit)
    v
EmployeeCubit.registerEmployee(...)  → emite loading y después success | failure
    |                                   devuelve true | false
    v
EmployeeRepository.registerEmployee (contrato)
    ^
    |
EmployeeRepositoryImpl → EmployeeLocalDataSource.addEmployee
                          (asigna el id emp-N y crea al empleado activo)
```

**Campos:**

| Campo | Componente | Regla |
|---|---|---|
| Nombre completo | `TextFormField` | Obligatorio; se recortan espacios; sin restricciones de caracteres |
| Puesto | `TextFormField` | Obligatorio; se recortan espacios |
| Área | `DropdownButtonFormField` (`isExpanded`) | Obligatoria; opciones de `employeeAreas` (dominio), coherentes con los datos ficticios |
| Género | `DropdownButtonFormField` | Obligatorio; valores de `Gender` |
| Fecha de ingreso | `showDatePicker` | Obligatoria; no puede ser futura |
| Fecha de nacimiento | `showDatePicker` | Obligatoria; anterior a hoy y a la fecha de ingreso; sin edad mínima |

**Validaciones:**

- Las reglas están en `presentation/validators/employee_form_validators.dart` como funciones puras, fuera de los widgets.
- Reciben la fecha de referencia como parámetro, de modo que las pruebas no dependen de la fecha real.
- Los selectores de fecha limitan además el rango elegible:
  - ingreso: hasta hoy, y después del nacimiento si ya se eligió;
  - nacimiento: hasta el día anterior al ingreso, o hasta ayer si aún no hay ingreso.
- La capa de datos no repite estas validaciones de interfaz.

**Estado de la pantalla:**

- La pantalla solo guarda el estado propio del formulario: los valores capturados, `_isSubmitting` y el mensaje de error del envío.
- No copia la lista de empleados.
- Mientras `_isSubmitting` es `true`, el botón y los campos se deshabilitan y se ignoran pulsaciones repetidas, así que no se crean duplicados.

**Resultado:**

- **Éxito** (`registerEmployee` devuelve `true`): se reemplaza la ruta por `EmployeeRegistrationSuccessPage`. Su botón «Volver al listado» regresa a `EmployeesPage`, que ya muestra al nuevo empleado.
- **Fallo** (`false`): se muestra el mensaje del estado (`errorMessage`), se conservan los datos capturados y se puede reintentar. Nunca se muestra la pantalla de éxito.
- **Cancelar**: regresa al listado sin llamar al Cubit.
- Después del `await` se comprueba `mounted` antes de usar el `BuildContext`.

**Cómo se actualiza la lista sin perder empleados:**

- `EmployeeCubit.registerEmployee` emite `employees: [...state.employees, employee]`: una lista **nueva**, con los empleados anteriores y el registrado al final. `copyWith` la vuelve no modificable.
- Los totales (`totalCount`, `activeCount`, `inactiveCount`) se recalculan a partir de esa lista.
- No hace falta volver a consultar la fuente de datos. Si se consulta, la fuente en memoria también conserva al empleado mientras la aplicación siga abierta.

**Localización:** `app.dart` configura `flutter_localizations` (incluido en el SDK) con `es_MX`, de modo que el selector de fechas y los textos de Material se muestran en español.

## Navegación y estado compartido

La navegación usa `Navigator` con `MaterialPageRoute`, sin paquetes adicionales:

```text
EmployeesPage ──push──► EmployeeFormPage ──pushReplacement──► EmployeeRegistrationSuccessPage
      ▲                       │ Cancelar (pop)                          │ Volver al listado (pop)
      └───────────────────────┴─────────────────────────────────────────┘
```

Flujo de datos de un registro:

```text
Listado → Formulario → Validación → EmployeeCubit → EmployeeRepository (contrato)
        → EmployeeRepositoryImpl → EmployeeLocalDataSource → estado actualizado → Listado
```

**Cómo se conserva el estado durante la navegación:**

- `EmployeeCubit` se crea **una sola vez** en `app.dart`, con un `BlocProvider` situado por encima de `MaterialApp`. Todas las rutas que crea el `Navigator` cuelgan de ese punto y leen la misma instancia con `context.read`.
- Ninguna ruta crea su propio Cubit. Un `BlocProvider(create: …)` dentro de una ruta crearía otra fuente de verdad; es el Error 1 de [depuracion-fase-6.md](depuracion-fase-6.md).
- El repositorio se crea una vez en `main.dart`. Reconstruir `EmployeeManagementApp` no recrea el Cubit ni vuelve a cargar los datos, porque el `BlocProvider` conserva su instancia. Hay una prueba que lo verifica.
- La carga inicial (`loadEmployees`) se dispara al crear el Cubit, no al volver al listado. Regresar de otra pantalla no sobrescribe los cambios de la sesión.
- Los widgets no guardan copias de la lista. Los cambios de estado activo/inactivo y los registros viven en el estado del Cubit y se ven en cualquier pantalla.

**Cómo se comunica el resultado del registro:**

- El formulario espera `await cubit.registerEmployee(...)`, que devuelve `true` o `false` en coherencia con el estado emitido (`success` o `failure`).
- Solo con `true` navega a la confirmación, una única vez y como consecuencia del resultado, no de un `BlocListener` que pueda volver a dispararse con cada reconstrucción.
- El listado no necesita un valor de retorno del `Navigator`: al volver, ya refleja el estado del Cubit compartido.
- Con `false`, el formulario muestra el error, conserva los datos y permite reintentar. El `SnackBar` de errores del listado solo aparece cuando el listado es la ruta visible, así que el mensaje no se duplica.

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
| `presentation/pages/employee_form_page_test.dart` | Campos, cada validación obligatoria, rangos de los selectores de fecha, envío válido con datos depurados, error con reintento, envíos repetidos y cancelación |
| `presentation/validators/employee_form_validators_test.dart` | Reglas de texto, selección y coherencia de fechas |
| `employee_registration_flow_test.dart` | Flujo listado → formulario → éxito → listado con el repositorio real, y registro fallido |
| `test/app_flow_test.dart` | Aplicación completa (`EmployeeManagementApp`): navegación, cancelación, confirmación única, formularios duplicados, error sin navegación de éxito, cambios que sobreviven a la navegación, sin duplicados, reconstrucción sin recrear el Cubit, reintento de carga y teclado abierto en pantalla pequeña |
| `test/core/utils/date_formatter_test.dart` | Formato `dd/MM/yyyy` |
| `test/widget_test.dart` | Arranque, Material 3 y carga de los empleados ficticios |

Salvo las tres últimas filas, las rutas son relativas a `test/features/employees/`. Los pasos para completar el formulario se comparten en `test/helpers/employee_form_helpers.dart`.

Las pruebas de la página siguen dos estrategias:

- Un `MockCubit` (`bloc_test`) para fijar cada estado de presentación.
- El `EmployeeCubit` real con un repositorio simulado (`mocktail`) para verificar que la interfaz reacciona a los estados que emite.

`test/app_flow_test.dart` usa un `CountingEmployeeRepository`: delega en la implementación en memoria real y cuenta las cargas y los registros, lo que permite verificar que no hay recargas ni registros de más.

Los defectos intencionales están documentados en [depuracion-fase-3.md](depuracion-fase-3.md), [depuracion-fase-4.md](depuracion-fase-4.md), [depuracion-fase-5.md](depuracion-fase-5.md) y [depuracion-fase-6.md](depuracion-fase-6.md).
