# Depuración intencional — Fase 5

Este documento registra tres defectos introducidos a propósito en el registro de empleados para practicar el ciclo de reproducción, diagnóstico, corrección y verificación.

- **Rama de práctica:** `practice/errores-controlados-fase-5`, creada desde `7a53e8e`, con el registro funcional y 87 pruebas en verde.
- **Rama funcional:** `feature/registro-empleados`. Nunca recibió los defectos y la rama de práctica **no** se fusionó.
- Las pruebas que detectaron los defectos ya existían en la rama funcional. No hubo que trasladar nada desde la práctica.
- Los defectos se trabajaron de uno en uno. Tras cada corrección se comprobó con `git diff feature/registro-empleados -- lib test` que el código era idéntico al de la rama funcional.
- Las salidas son extractos reales de `flutter test` y `flutter analyze`. En los tres casos `flutter analyze` respondió `No issues found!`.

| Ejercicio | Commit del defecto | Commit de la corrección |
|---|---|---|
| Error 1 | `e0846e5` | `e5f4c12` |
| Error 2 | `b423cbb` | `ba0b293` |
| Error 3 | `ce742c5` | `89ce603` |

---

## Error 1 — Validación incompleta del puesto

- **Categoría:** validación de formulario.
- **Archivo:** `lib/features/employees/presentation/pages/employee_form_page.dart` (campo `Puesto`).

**Comportamiento esperado.** Con el puesto vacío, el formulario muestra «Ingresa el puesto.» y **no** llama a `EmployeeCubit.registerEmployee`.

**Defecto introducido.** Se quitó `validator: EmployeeFormValidators.position` del `TextFormField` del puesto.

**Comportamiento observado.** `flutter test` → `+85 -2: Some tests failed.`

- *EmployeeFormPage — validaciones un formulario vacío muestra todos los errores*:

  ```text
  Expected: exactly one matching candidate
    Actual: _TextWidgetFinder:<Found 0 widgets with text "Ingresa el puesto.": []>
  employee_form_page_test.dart line 145
  ```

- *EmployeeFormPage — validaciones un puesto vacío impide registrar*:

  ```text
  The following _TypeError was thrown running a test:
  type 'Null' is not a subtype of type 'Future<bool>'
  #0  MockEmployeeCubit.registerEmployee (...employee_form_page_test.dart:17:7)
  #1  _EmployeeFormPageState._submit (...employee_form_page.dart:71:36)
  ```

  El mensaje es indirecto, pero la pila demuestra el defecto. `_submit` llegó a invocar `registerEmployee` con el puesto vacío, y el mock no tenía respuesta configurada porque la prueba espera que nunca se llame. Por eso se revisó la pila antes de atribuir el fallo al ejercicio.

**Causa raíz.** El campo no tenía validador. `FormState.validate()` devolvía `true` aunque faltara un dato obligatorio.

**Solución aplicada.** Restaurar `validator: EmployeeFormValidators.position`.

**Resultado posterior.** *puesto vacío*: `+1: All tests passed!`. *formulario vacío*: `+1: All tests passed!`. Batería completa: `+87: All tests passed!`. `flutter analyze`: `No issues found!`.

---

## Error 2 — Pérdida de empleados anteriores al registrar

- **Categoría:** actualización incorrecta de la colección.
- **Archivo:** `lib/features/employees/presentation/cubit/employee_cubit.dart` (`registerEmployee`).

**Comportamiento esperado.** Tras registrar, la lista del estado es una lista **nueva** con los empleados existentes y el registrado al final: `[...state.employees, employee]`.

**Defecto introducido.** `employees: [employee]`.

**Comportamiento observado.** `flutter test` → `+83 -4: Some tests failed.`

- *EmployeeCubit.registerEmployee agrega el empleado registrado al final de la lista actual* (`bloc_test`): la secuencia de estados no coincide; el estado de éxito solo contiene al empleado nuevo.
- *EmployeeCubit con el repositorio en memoria el registrado queda activo y se conservan los anteriores* y *tras registrar se puede cambiar el estado del nuevo empleado*:

  ```text
  Expected: <6>
    Actual: <1>
  ```

- *registrar desde el listado agrega al empleado y actualiza los totales* (flujo entre pantallas):

  ```text
  Expected: exactly 6 matching candidates
    Actual: _TypeWidgetFinder:<Found 1 widget with type "EmployeeCard": [EmployeeCard-[<'emp-6'>] ...
  ```

  Al volver al listado solo aparecía el empleado nuevo. Los cinco anteriores seguían en la fuente de datos, pero desaparecían de la pantalla.

**Causa raíz.** La lista emitida se construía a partir del resultado de la operación, no a partir de `state.employees`.

**Solución aplicada.** Restaurar `employees: [...state.employees, employee]`. Crea una colección nueva, que `copyWith` vuelve no modificable, sin mutar la anterior.

**Resultado posterior.** Las pruebas del Cubit y del flujo dan `+16: All tests passed!`, la batería completa `+87: All tests passed!` y `flutter analyze` `No issues found!`.

---

## Error 3 — Éxito falso ante un error del repositorio

- **Categoría:** gestión de estado y resultado de la operación.
- **Archivo:** `lib/features/employees/presentation/cubit/employee_cubit.dart` (`registerEmployee`).

**Comportamiento esperado.** Si el repositorio lanza una excepción, el Cubit emite `failure`, conserva la lista y devuelve `false`. Con ese resultado, el formulario:

- no navega a la pantalla de éxito;
- muestra el mensaje de error;
- conserva los datos capturados;
- permite reintentar.

**Defecto introducido.** En el `catch`, tras `_emitFailure`, el método devolvía `true`.

**Comportamiento observado.** `flutter test` → `+85 -2: Some tests failed.`

- *EmployeeCubit.registerEmployee si el registro falla emite fallo y conserva la lista*:

  ```text
  Expected: false
    Actual: <true>
  ```

- *un registro fallido no agrega al empleado y cancelar vuelve al listado* (flujo entre pantallas):

  ```text
  Expected: exactly one matching candidate
    Actual: _TextWidgetFinder:<Found 0 widgets with text "No se pudo registrar al empleado.": []>
  employee_registration_flow_test.dart line 142
  ```

  El Cubit estaba en `failure` y no había agregado al empleado. Sin embargo, el formulario recibió `true`, salió con `pushReplacement` hacia la pantalla de éxito y el mensaje de error nunca se mostró. La afirmación siguiente de la prueba («Empleado registrado» no debe aparecer) no llegó a ejecutarse porque la prueba se detuvo en la línea 142.

**Causa raíz.** El valor devuelto contradecía al estado emitido. El formulario decide la navegación con ese valor, así que el usuario recibía una confirmación falsa.

**Solución aplicada.** Restaurar `return false;` en el `catch`.

**Resultado posterior.**

| Prueba | Resultado |
|---|---|
| *si el registro falla…* | `+1: All tests passed!` |
| Flujo entre pantallas (éxito y fallo) | `+2: All tests passed!` |
| *un error del registro se muestra y permite reintentar* (formulario) | `+1: All tests passed!` |
| Batería completa | `+87: All tests passed!` |

`flutter analyze`: `No issues found!`.

---

## Lecciones

- Cada campo obligatorio necesita su propia prueba de «vacío impide registrar». Una única prueba de «formulario vacío» no indica qué campo perdió su validación.
- Ante un fallo con un mensaje inesperado (Error 1, `TypeError` en el mock), hay que leer la pila antes de concluir: aquí demostraba que se llamó al registro cuando no debía.
- Las pruebas de flujo completo entre pantallas detectan defectos que el usuario vería directamente: lista incompleta (Error 2) y confirmación falsa (Error 3).
- Si una operación informa su resultado de dos formas (estado emitido y valor devuelto), ambas deben probarse y ser coherentes.
