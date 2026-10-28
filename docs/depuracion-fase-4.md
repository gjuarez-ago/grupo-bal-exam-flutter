# Depuración intencional — Fase 4

Este documento registra tres defectos introducidos a propósito en la pantalla de listado para practicar el ciclo de reproducción, diagnóstico, corrección y verificación.

- **Rama de práctica:** `practice/errores-controlados-fase-4`, creada desde `dada43b`, con la implementación funcional y 56 pruebas en verde.
- **Rama funcional:** `feature/listado-empleados`. Nunca recibió los defectos y la rama de práctica **no** se fusionó.
- Solo se trasladó a la rama funcional, con `cherry-pick`, la prueba nueva escrita durante el Error 2 (`58d1922` → `8a29145`). Antes se revisó que solo tocara el archivo de pruebas.
- Los defectos se trabajaron de uno en uno. Tras cada corrección se comprobó con `git diff feature/listado-empleados -- lib` que el código de producción era idéntico al de la rama funcional.
- Las salidas son extractos reales de `flutter test` y `flutter analyze` ejecutados durante la práctica. En los tres casos `flutter analyze` respondió `No issues found!`: ninguno de los defectos es detectable por análisis estático.

| Ejercicio | Commit del defecto | Commits de prueba / corrección |
|---|---|---|
| Error 1 | `214fa6f` | `939ed31` (fix) |
| Error 2 | `9c9b773` | `58d1922` (prueba nueva), `540f2b1` (fix) |
| Error 3 | `bd74ee3` | `bf25a44` (fix) |

---

## Error 1 — Contador de activos incorrecto

- **Categoría:** regresión de lógica en un valor derivado.
- **Archivo:** `lib/features/employees/presentation/cubit/employee_state.dart` (getter `activeCount`).

**Comportamiento esperado.** Con tres empleados, dos activos y uno inactivo, el resumen muestra Total 3, Activos 2 e Inactivos 1.

**Defecto introducido.** `int get activeCount => employees.length;`. Cuenta a todos los empleados sin comprobar `isActive`.

**Comportamiento observado.** `flutter test` → `+51 -5: Some tests failed.`

- `EmployeeState contadores cuenta activos e inactivos según el estado de cada empleado`:

  ```text
  Expected: <2>
    Actual: <3>
  ```

- Cuatro pruebas de `employees_page_test.dart`: *los contadores coinciden con la lista*, *desactivar actualiza la tarjeta y recalcula los contadores*, *un fallo al cambiar el estado no se muestra como éxito* y *reintentar tras un error de carga muestra la lista*:

  ```text
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "2" descending from
          widgets with key [<'employee-summary-active'>]: []>
   Which: means none were found but one was expected
  ```

**Causa raíz.** El total de activos se calculaba con el tamaño de la colección y no filtraba por estado. Como `inactiveCount` se deriva como `totalCount - activeCount`, el error se propagaba: mostraba 0 inactivos.

**Solución aplicada.** Restaurar `employees.where((employee) => employee.isActive).length`.

**Resultado posterior.** Las pruebas del estado y de la página dan `+16: All tests passed!`, la batería completa `+56: All tests passed!` y `flutter analyze` `No issues found!`.

---

## Error 2 — Interruptor desincronizado del Cubit

- **Categoría:** error de sincronización entre interfaz y estado.
- **Archivo:** `lib/features/employees/presentation/widgets/employee_status_control.dart`.

**Comportamiento esperado.** El interruptor muestra siempre `employee.isActive` del último estado emitido por el Cubit, tanto si el cambio lo inicia el usuario como si llega desde el Cubit, y tanto si la operación tiene éxito como si falla.

**Defecto introducido.** `EmployeeStatusControl` pasó a ser `StatefulWidget` con una copia local `late bool _value = widget.value`:

- solo se inicializa una vez, sin `didUpdateWidget`;
- se cambia de forma optimista con `setState` antes de conocer el resultado.

**Comportamiento observado.**

1. Con la batería existente, `flutter test` → `+55 -1: Some tests failed.` en *un fallo al cambiar el estado no se muestra como éxito*:

   ```text
   Expected: true
     Actual: <false>
   ... employees_page_test.dart line 331
   ```

   La línea 330 (`cubit.state.status == failure`) pasaba: el Cubit conservaba a `emp-1` como activo. La línea 331 fallaba: el interruptor mostraba «inactivo». Mientras tanto, la etiqueta de la misma tarjeta seguía diciendo «Activo». El usuario veía un resultado falso.

2. Se escribió una prueba nueva que reproduce la desincronización sin interacción del usuario: *el interruptor refleja cambios emitidos por el Cubit*. Esa prueba llama a `cubit.updateEmployeeStatus(id: 'emp-3', isActive: true)` directamente y falla con el defecto:

   ```text
   Expected: true
     Actual: <false>
   ... employees_page_test.dart line 332
   ```

   La línea 331 (`cubit.state.employees[2].isActive == true`) pasaba y la 332 (valor del interruptor) fallaba.

**Causa raíz.** Había dos fuentes de verdad. La copia local del widget no se actualizaba cuando cambiaba el estado del Cubit, y además adelantaba un resultado que el Cubit podía rechazar.

**Solución aplicada.** Eliminar la copia local y devolver `EmployeeStatusControl` a `StatelessWidget`, que muestra siempre `value`. La alternativa de agregar `didUpdateWidget` se descartó: mantendría el cambio optimista y la doble fuente de verdad.

**Resultado posterior.**

- *el interruptor refleja cambios…* y las demás pruebas del interruptor: `+3: All tests passed!`.
- *un fallo al cambiar el estado…*: `+1: All tests passed!`.
- Batería completa: `+57: All tests passed!`. `flutter analyze`: `No issues found!`.

La prueba nueva también comprueba que `emp-1` y `emp-2` conservan sus valores.

---

## Error 3 — El error de carga se presenta como lista vacía

- **Categoría:** condición de presentación incorrecta.
- **Archivo:** `lib/features/employees/presentation/pages/employees_page.dart` (método `_buildBody`).

**Comportamiento esperado.**

| Estado | Lista | Se muestra |
|---|---|---|
| `initial` / `loading` | vacía | Indicador de progreso |
| `success` | vacía | «Todavía no hay empleados registrados.» |
| `failure` | vacía | «No se pudieron cargar los empleados.», el mensaje del error y «Reintentar» |

**Defecto introducido.** Antes del `switch`, una condición devolvía la vista de lista vacía para cualquier estado distinto de `loading` e `initial`, incluido `failure`.

**Comportamiento observado.** `flutter test` → `+55 -2: Some tests failed.` en *un error de carga muestra el mensaje y permite reintentar* y *reintentar tras un error de carga muestra la lista*:

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "No se pudieron cargar los empleados.": []>
   Which: means none were found but one was expected
```

El usuario veía «Todavía no hay empleados registrados.», una afirmación falsa, y no tenía forma de reintentar. El analizador no avisó porque el `switch` seguía siendo exhaustivo; simplemente la rama `failure` ya no se alcanzaba con la lista vacía.

**Causa raíz.** La condición decidía la vista según si la lista estaba vacía y no según el `status`. «Lista vacía» y «carga fallida» comparten `employees == []`, pero solo `status` las distingue.

**Solución aplicada.** Eliminar la condición previa y dejar que el `switch` sobre `status` decida la vista.

**Resultado posterior.** Cada estado se comprobó por separado:

| Prueba | Resultado |
|---|---|
| *durante la carga* | `+1: All tests passed!` |
| *antes de cargar* | `+1: All tests passed!` |
| *una lista vacía* | `+1: All tests passed!` |
| *un error de carga* | `+2: All tests passed!` (incluye el reintento simulado) |
| *reintentar tras un error de carga* | `+1: All tests passed!` (reintento real con el Cubit) |

La batería completa dio `+57: All tests passed!` y `flutter analyze` `No issues found!`.

---

## Lecciones

- Los valores derivados (totales) deben calcularse a partir de la colección y probarse con datos mixtos. Una lista en la que todos están activos no habría detectado el Error 1.
- En la interfaz, una sola fuente de verdad: los widgets muestran el estado del Cubit y no lo copian.
- La vista debe decidirse por el `status` del estado, no por características de los datos que comparten varios estados.
