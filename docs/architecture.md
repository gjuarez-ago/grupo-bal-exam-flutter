# Arquitectura

> **Estado:** Fase 2 (arquitectura base). Ya existen la entidad `Employee`, el contrato `EmployeeRepository`, los estados y `EmployeeCubit` (solo carga de empleados) y el tema Material 3. Todavía **no** existen la implementación de datos, la fuente mock ni las pantallas de empleados.

## Enfoque

El proyecto sigue Clean Architecture organizada por funcionalidades (*features*). Cada módulo agrupa sus propias capas, de modo que el código de una funcionalidad vive junto y no se dispersa en carpetas globales.

## Flujo conceptual

```text
Presentación
    |
    v
EmployeeCubit
    |
    v
Contrato EmployeeRepository
    ^
    |
Implementación de datos (fase posterior)
    |
    v
Fuente mock local (fase posterior)
```

El diagrama representa la relación arquitectónica prevista. Las dos últimas cajas aún no están implementadas.

## Dependencias permitidas entre capas

| Capa | Puede depender de | No puede depender de |
|---|---|---|
| `domain` | Dart puro y `equatable` | Flutter, `flutter_bloc`, `data`, `presentation` |
| `data` | `domain` | `presentation` |
| `presentation` | `domain`, Flutter, `flutter_bloc` | Implementaciones de `data` |

El dominio no depende de Flutter ni de la implementación de datos porque contiene las reglas de negocio: así puede probarse sin interfaz y la fuente de datos (mock, red o almacenamiento local) puede sustituirse sin modificar el dominio ni la presentación. La implementación concreta se inyectará desde la raíz de la aplicación en la Fase 3.

## Componentes

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

Usa `equatable` para comparar por valor. Esto facilita las pruebas y la comparación de estados. No tiene anotaciones de serialización ni lógica de presentación.

### Contrato `EmployeeRepository`

`lib/features/employees/domain/repositories/employee_repository.dart`

Clase abstracta con las operaciones del módulo. Todas devuelven `Future` para admitir más adelante fuentes asíncronas sin cambiar el contrato.

- `getEmployees()`: devuelve todos los empleados. Una lista vacía es un resultado válido.
- `registerEmployee(...)`: recibe los datos del empleado **sin** `id` ni `isActive`. La implementación asigna el `id` y registra al empleado como activo, y devuelve el `Employee` resultante.
- `updateEmployeeStatus(id:, isActive:)`: cambia el estado activo y devuelve el empleado actualizado.

**Manejo de errores:** las implementaciones lanzan `EmployeeRepositoryException` (con un `message` comprensible) ante fallos esperados, y `EmployeeNotFoundException` cuando el `id` no existe.

### Estados `EmployeeState`

`lib/features/employees/presentation/cubit/employee_state.dart`

Es una única clase inmutable, con `equatable`, que tiene:

- `status`: `EmployeeStatus.initial`, `loading`, `success` o `failure`.
- `employees`: lista no modificable de empleados (vacía por defecto).
- `errorMessage`: solo tiene valor cuando `status` es `failure`.

Se eligió una sola clase en lugar de una por estado para conservar la lista durante una recarga sin duplicar campos.

### `EmployeeCubit`

`lib/features/employees/presentation/cubit/employee_cubit.dart`

Recibe `EmployeeRepository` por constructor; no crea ni conoce la implementación concreta. Por ahora solo implementa `loadEmployees()`:

1. Emite `loading`, conservando los empleados actuales.
2. Si la carga tiene éxito, emite `success` con la lista.
3. Si se produce una `EmployeeRepositoryException`, emite `failure` con su mensaje.
4. Si se produce cualquier otro error, lo reporta con `addError` (llega al `BlocObserver`) y emite `failure` con un mensaje genérico.

### Tema

`lib/core/theme/app_theme.dart` define un tema claro basado en Material 3, generado a partir de un color semilla índigo.

## Pruebas

Las pruebas están en `test/` y reflejan la estructura de `lib/`:

- `features/employees/domain/entities/employee_test.dart`: construcción e igualdad de la entidad.
- `features/employees/presentation/cubit/employee_cubit_test.dart`: transiciones del Cubit con un repositorio simulado mediante `mocktail` y `bloc_test` (éxito, lista vacía, error esperado, error inesperado y recarga).
- `widget_test.dart`: arranque de la aplicación y uso de Material 3.

## Pendiente para la Fase 3

- Fuente de datos mock local (`data/datasources`).
- Implementación concreta de `EmployeeRepository` (`data/repositories`).
- Operaciones de registro y cambio de estado en `EmployeeCubit`.
- Inyección del repositorio y del Cubit en la raíz de la aplicación.
- Pantallas y widgets de empleados.
