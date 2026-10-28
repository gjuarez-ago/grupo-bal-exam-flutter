# Depuración intencional — Fase 3

Este documento registra tres defectos introducidos a propósito para practicar el ciclo de reproducción, diagnóstico, corrección y verificación.

- **Rama de práctica:** `practice/errores-controlados-fase-3`, creada desde `a05321d` (implementación funcional con 31 pruebas en verde).
- **Rama funcional:** `feature/capa-datos-empleados`. Nunca recibió los defectos y la rama de práctica **no** se fusionó.
- Los defectos se trabajaron de uno en uno. Al cerrar cada ejercicio se comprobó con `git diff feature/capa-datos-empleados -- lib test` que el código corregido era idéntico al de la rama funcional.
- Las salidas que aparecen abajo son extractos reales de `flutter test` y `flutter analyze` ejecutados durante la práctica.

| Ejercicio | Commit del defecto | Commit de la corrección |
|---|---|---|
| Error 1 | `12d65a2` | `23eaba9` |
| Error 2 | `18448ca` | `c30ae49` |
| Error 3 | `eebb546` | `6674eab` |

---

## Error 1 — Actualización del empleado equivocado

- **Categoría:** error lógico.
- **Archivo y responsabilidad:** `lib/features/employees/data/datasources/employee_local_data_source.dart`, método `updateEmployeeStatus`, encargado de localizar y reemplazar un empleado en la lista en memoria.

**Comportamiento esperado.** `updateEmployeeStatus(id: 'emp-2', isActive: false)` modifica únicamente a `emp-2` y devuelve ese empleado actualizado.

**Defecto introducido.** Después de validar que el id existe, el índice se calculaba a partir del número del id (`int.parse(id.split('-').last)`) en lugar de usar el resultado de `indexWhere`. Como la lista empieza en 0 y los ids en 1, siempre se modificaba al empleado siguiente.

**Pasos de reproducción.**

1. `git checkout 12d65a2`
2. `flutter analyze` → `No issues found!`. El código compila y no hay problemas de análisis estático.
3. `flutter test` → `+29 -2: Some tests failed.`

**Pruebas que lo detectaron.**

- `EmployeeLocalDataSource actualizar el estado modifica solo el empleado indicado`:

  ```text
  Expected: 'emp-2'
    Actual: 'emp-3'
  ```

- `EmployeeRepositoryImpl actualiza el estado y conserva a los demás empleados`:

  ```text
  Expected: Employee(emp-1, Ana Sofía López Ramírez, ..., false)
    Actual: Employee(emp-2, Carlos Alberto Pérez Núñez, ..., false)
  ```

**Comportamiento observado.** Se desactivaba al empleado equivocado, y el empleado solicitado permanecía sin cambios. Es un fallo de comportamiento, no de compilación ni de análisis.

**Causa raíz.** Se asumía que el id y la posición en la lista coinciden. Esa relación no forma parte del contrato: los ids son opacos y el orden de la lista puede cambiar.

**Solución aplicada.** Usar el `index` obtenido con `indexWhere((employee) => employee.id == id)`, que ya se calculaba para validar la existencia.

**Verificación posterior.** Las pruebas de la fuente local y del repositorio dan `+13: All tests passed!`, la batería completa `+31: All tests passed!` y `flutter analyze` `No issues found!`.

**Por qué no se corrige cambiando la prueba.** La prueba expresa el requisito («cambiar el estado de *ese* empleado»). Ajustar la expectativa a `emp-3` legitimaría que el usuario desactive a otra persona.

---

## Error 2 — Fallo silenciado en el Cubit

- **Categoría:** error de gestión de estado.
- **Archivo y responsabilidad:** `lib/features/employees/presentation/cubit/employee_cubit.dart`, método `updateEmployeeStatus`, encargado de traducir el resultado del repositorio a estados.

**Comportamiento esperado.** Si el repositorio lanza `EmployeeNotFoundException`, el Cubit emite `loading` y después `failure`, con el mensaje del error y la lista intacta. El método devuelve `false` y el Cubit sigue operativo.

**Defecto introducido.** El bloque `catch` devolvía `false` sin llamar a `_emitFailure`.

**Pasos de reproducción.**

1. `git checkout 18448ca`
2. `flutter analyze` → `No issues found!`
3. `flutter test` → `+29 -2: Some tests failed.` El repositorio se simula con `mocktail` (`MockEmployeeRepository`) para que lance la excepción.

**Pruebas que lo detectaron y estados emitidos.**

- `EmployeeCubit.updateEmployeeStatus un id inexistente emite fallo sin modificar la lista`:

  ```text
  Expected: [EmployeeState(loading, [...], null),
             EmployeeState(failure, [...], No se encontró el empleado con id no-existe.)]
    Actual: [EmployeeState(loading, [...], null)]
  ```

- `EmployeeCubit.updateEmployeeStatus después de un fallo el Cubit puede seguir operando`:

  ```text
  Actual: []
   Which: at location [0] is [] which shorter than expected
  ```

**Comportamiento observado.** El Cubit quedaba en `loading` de forma permanente y la interfaz no tenía forma de saber que la operación falló. La segunda prueba revela un efecto adicional: la siguiente operación emite `loading`, que es igual al estado actual, y Cubit descarta los estados repetidos. Por eso la secuencia observada fue más corta de lo esperado.

**Causa raíz.** El error se capturaba pero no se transformaba en un estado. Capturar sin emitir equivale a ocultar el fallo.

**Solución aplicada.** Restaurar `catch (error, stackTrace) { _emitFailure(error, stackTrace); return false; }`. El manejo de errores sigue centralizado en el Cubit y no se agregó lógica de interfaz.

**Verificación posterior.** Las pruebas del Cubit dan `+11: All tests passed!`, la batería completa `+31: All tests passed!` y `flutter analyze` `No issues found!`.

**Por qué no se corrige cambiando la prueba.** Aceptar `[loading]` como resultado válido significaría que una operación fallida nunca termina para la interfaz.

---

## Error 3 — Regresión al registrar un empleado

- **Categoría:** defecto de comportamiento detectado mediante pruebas (regresión).
- **Archivo y responsabilidad:** `lib/features/employees/presentation/cubit/employee_cubit.dart`, método `registerEmployee`, encargado de incorporar el empleado nuevo a la lista del estado.

**Comportamiento esperado.** Después de registrar, la lista emitida contiene a los empleados existentes seguidos del nuevo: `[emp-1, emp-2, emp-3]`.

**Defecto introducido.** Se emitía `employees: [employee]`, que reemplaza la colección completa.

**Pasos de reproducción.**

1. `git checkout eebb546`
2. `flutter analyze` → `No issues found!`
3. `flutter test` → `+30 -1: Some tests failed.`

**Prueba que lo detectó.** `EmployeeCubit.registerEmployee agrega el empleado registrado al final de la lista actual`:

```text
Which: at location [1] is EmployeeState(EmployeeStatus.success,
       [Employee(emp-3, Luis Ramírez, ...)], null) instead of ...
```

**Comportamiento observado.** El estado de éxito contenía solo al empleado nuevo. Los empleados previos desaparecían de la vista aunque seguían existiendo en el repositorio.

**Causa raíz.** La lista se construía a partir del resultado de la operación en lugar de a partir de `state.employees`.

**Solución aplicada.** Restaurar `employees: [...state.employees, employee]`.

**Verificación posterior.** Las pruebas del Cubit dan `+11: All tests passed!`, la batería completa `+31: All tests passed!` y `flutter analyze` `No issues found!`. Ninguna prueba previa se eliminó ni se modificó.

**Por qué no se corrige cambiando la prueba.** La prueba protege que registrar no tenga efectos secundarios sobre los demás empleados; relajarla permitiría que la regresión vuelva a aparecer sin aviso.

---

## Lecciones

- `flutter analyze` no detectó ninguno de los tres defectos: los tres son errores de comportamiento que solo las pruebas descubren.
- Las pruebas que comparan la secuencia completa de estados (`bloc_test`) y la lista completa tras una operación detectan tanto errores de lógica como efectos secundarios.
- Antes de corregir hay que leer el mensaje completo del fallo. En el Error 2, `Actual: []` no significaba que el Cubit no emitiera nada, sino que los estados repetidos se descartan.
