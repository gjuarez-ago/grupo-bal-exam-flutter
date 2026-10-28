# Depuración intencional — Fase 6

Este documento registra tres defectos introducidos a propósito en la integración entre pantallas para practicar el ciclo de reproducción, diagnóstico, corrección y verificación.

- **Rama de práctica:** `practice/errores-controlados-fase-6`, creada desde `89543e2`, con la integración funcional y 99 pruebas en verde.
- **Rama funcional:** `feature/integracion-navegacion`. Nunca recibió los defectos y la rama de práctica **no** se fusionó.
- Las pruebas que detectaron los defectos ya existían en la rama funcional (sobre todo `test/app_flow_test.dart`). No hubo que trasladar nada.
- Los defectos se trabajaron de uno en uno. Cada corrección se aplicó restaurando el archivo desde la rama funcional (`git checkout feature/integracion-navegacion -- <archivo>`), y se comprobó con `git diff feature/integracion-navegacion -- lib test` que no quedaban diferencias.
- Las salidas son extractos reales de `flutter test` y `flutter analyze`. En los tres casos `flutter analyze` respondió `No issues found!`.

| Ejercicio | Commit del defecto | Commit de la corrección |
|---|---|---|
| Error 1 | `c7819b0` | `4777331` |
| Error 2 | `fef0c65` | `5e62cb6` |
| Error 3 | `89e5c2e` | `7f1198c` |

## Hallazgo previo a los ejercicios (defecto real, no intencional)

Al escribir las pruebas de la Fase 6, la prueba *el formulario se puede usar con el teclado abierto en un móvil pequeño* falló con `A RenderFlex overflowed by 26 pixels on the right.`

Una prueba temporal (eliminada después) capturó los errores de Flutter y localizó el origen:

- el `DropdownButtonFormField` de **Área** (`employee_form_page.dart:192`);
- el error ocurría **al abrir el formulario** en 320 px de ancho, con o sin teclado.

**Causa.** Sin `isExpanded`, el botón del menú toma el ancho de la opción más larga («Recursos Humanos») más el ícono. Las pruebas del formulario de la Fase 5 usaban 400 px de ancho y no lo detectaron.

**Corrección.** `isExpanded: true` en los dos menús, en la rama funcional (`ab282dd`).

En la misma ronda falló otra prueba con `Bad state: No element`, pero era un error **de la prueba**: buscaba `EmployeesPage` mientras el formulario estaba encima, y la página quedaba fuera de escena. Se corrigió con `skipOffstage: false`.

---

## Error 1 — Instancia incorrecta del Cubit

- **Categoría:** ciclo de vida e inyección de dependencias.
- **Archivo:** `lib/features/employees/presentation/pages/employees_page.dart` (ruta que abre el formulario).

**Comportamiento esperado.** El formulario usa el mismo `EmployeeCubit` que el listado, creado una sola vez en `app.dart`. Al registrar, el listado muestra al nuevo empleado.

**Defecto introducido.** La ruta del formulario se envolvió en `BlocProvider(create: (context) => EmployeeCubit(context.read<EmployeeRepository>()))`. El formulario obtenía así un Cubit nuevo y vacío.

**Comportamiento observado.** `flutter test` → `+92 -7: Some tests failed.`

Las 5 pruebas de `test/app_flow_test.dart` usan la composición real (`EmployeeManagementApp` con `RepositoryProvider`) y muestran el síntoma puro:

```text
Expected: exactly 6 matching candidates
  Actual: _TypeWidgetFinder:<Found 5 widgets with type "EmployeeCard": [...]
...
Expected: 'Luis Ramírez'
  Actual: 'Valeria Méndez Ortega'
...
Expected: <6>
  Actual: <5>
```

El segundo Cubit registraba en el repositorio compartido, pero el Cubit del listado no se enteraba: seguía mostrando 5 empleados y el último era el ficticio original.

Las 2 pruebas de `test/features/employees/employee_registration_flow_test.dart` también fallaron por el defecto, pero con otro mecanismo. Su entorno de prueba solo provee el Cubit, sin `RepositoryProvider`:

```text
The following ProviderNotFoundException was thrown running a test:
Error: Could not find the correct Provider<EmployeeRepository> above this
_InheritedProviderScope<EmployeeCubit?> Widget
...
type 'Null' is not a subtype of type 'EmployeeCubit' in type cast
```

**Causa raíz.** Se creaba una segunda instancia del Cubit en una ruta hija, con lo que había dos fuentes de verdad para la lista.

**Solución aplicada.** Eliminar el `BlocProvider` local. La ruta vuelve a construir `EmployeeFormPage` directamente, y el formulario lee el Cubit compartido que está por encima de `MaterialApp`.

**Resultado posterior.** `app_flow_test.dart` y `employee_registration_flow_test.dart`: `+14: All tests passed!`. Batería completa: `+99: All tests passed!`. `flutter analyze`: `No issues found!`.

---

## Error 2 — Registro duplicado

- **Categoría:** actualización del estado tras una operación.
- **Archivo:** `lib/features/employees/presentation/cubit/employee_cubit.dart` (`registerEmployee`).

**Comportamiento esperado.** Un registro agrega **exactamente un** empleado a la lista: `[...state.employees, employee]`.

**Defecto introducido.** Después de registrar, se volvía a consultar `_repository.getEmployees()`, que ya incluye al empleado nuevo, y se emitía `[...refreshed, employee]`.

**Comportamiento observado.** `flutter test` → `+90 -9: Some tests failed.`

```text
Expected: <6>
  Actual: <7>
...
Expected: exactly 6 matching candidates
  Actual: _TypeWidgetFinder:<Found 7 widgets with type "EmployeeCard": [...]
...
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 2 widgets with key [<'emp-6'>]: [...]
```

La tarjeta `emp-6` aparecía dos veces y los totales mostraban 7.

Una de las fallas tuvo otro mecanismo: *EmployeeCubit.registerEmployee agrega el empleado registrado al final de la lista actual*. Esa prueba usa un repositorio simulado y dio `Expected: true, Actual: <false>`. El defecto agrega una llamada a `getEmployees()` que el mock no tiene configurada; esa llamada lanza un error, el Cubit lo captura y devuelve `false`. También es consecuencia del defecto: una consulta extra que no debe existir.

**Causa raíz.** Se combinaban dos estrategias de actualización: volver a leer la fuente y agregar el resultado de la operación. Cualquiera de las dos por separado es correcta; juntas duplican.

**Solución aplicada.** Restaurar la actualización única: agregar el empleado devuelto a `state.employees`, sin volver a consultar.

**Resultado posterior.** *volver al listado no duplica empleados*: `+1: All tests passed!`. Pruebas del Cubit: `+14: All tests passed!`. Batería completa: `+99: All tests passed!`. `flutter analyze`: `No issues found!`.

---

## Error 3 — Navegación de éxito tras un fallo

- **Categoría:** manejo del resultado de una operación asíncrona en la navegación.
- **Archivo:** `lib/features/employees/presentation/pages/employee_form_page.dart` (`_submit`).

**Comportamiento esperado.** El formulario espera `await cubit.registerEmployee(...)` y solo con `true` reemplaza la ruta por la confirmación. Con `false` muestra el error, conserva los datos y permite reintentar.

**Defecto introducido.** Navegación «optimista»: `unawaited(cubit.registerEmployee(...))` seguido de `pushReplacement` a la pantalla de éxito, sin consultar el resultado.

**Comportamiento observado.** `flutter test` → `+96 -3: Some tests failed.`

- *Navegación un error del repositorio no navega al éxito* (`app_flow_test.dart`):

  ```text
  Expected: no matching candidates
    Actual: _TextWidgetFinder:<Found 1 widget with text "Empleado registrado": [...]
  ```

- *un registro fallido no agrega al empleado y cancelar vuelve al listado*:

  ```text
  Expected: exactly one matching candidate
    Actual: _TextWidgetFinder:<Found 0 widgets with text "No se pudo registrar al empleado.": []>
  ```

- *EmployeeFormPage — envío un error del registro se muestra y permite reintentar*:

  ```text
  Expected: exactly one matching candidate
    Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'employee-form-submit-error'>]: []>
  ```

El repositorio había fallado y el Cubit estaba en `failure` sin el empleado, pero el usuario veía «Empleado registrado». El formulario ya no existía para mostrar el error ni permitir reintentar.

**Causa raíz.** La navegación no dependía del resultado de la operación. Se ejecutaba antes de conocerlo.

**Solución aplicada.** Restaurar el flujo: `final registered = await cubit.registerEmployee(...)`, comprobar `mounted`, y después navegar al éxito o mostrar el error según `registered`.

**Resultado posterior.**

| Prueba | Resultado |
|---|---|
| *no navega al éxito* | `+1: All tests passed!` |
| `employee_registration_flow_test.dart` | `+2: All tests passed!` |
| *permite reintentar* | `+1: All tests passed!` |
| Batería completa | `+99: All tests passed!` |

`flutter analyze`: `No issues found!`. La prueba de la aplicación también verifica que, tras el fallo, un segundo intento llega al repositorio (`registerCalls == 2`) y que, al cancelar, la lista sigue en 5/4/1.

---

## Lecciones

- Un `BlocProvider` con `create:` en una ruta hija crea **otra** fuente de verdad. Para compartir estado entre rutas, el Cubit debe proveerse por encima del `Navigator` (aquí, por encima de `MaterialApp`).
- Releer la fuente y agregar el resultado son estrategias excluyentes; combinarlas duplica.
- La navegación de éxito debe depender del resultado confirmado de la operación, nunca adelantarse a él.
- Un mismo defecto puede manifestarse distinto según el entorno de la prueba (Error 1: pérdida de estado o `ProviderNotFoundException`). Clasificar cada fallo evita atribuirle causas equivocadas.
