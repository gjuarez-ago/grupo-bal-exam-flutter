# Gestión de empleados

Una aplicación móvil sencilla para **ver, registrar y activar o desactivar empleados** de una empresa. Está hecha con Flutter como examen técnico.

## ¿Qué hace la aplicación?

**1. Muestra la lista de empleados.**
Al abrirla aparece la lista con cinco empleados de ejemplo. De cada uno se ve su nombre, área, puesto, género, fecha de entrada y si está **Activo** o **Inactivo**. Arriba se muestra cuántos empleados hay en total, cuántos activos y cuántos inactivos.

**2. Permite activar o desactivar a un empleado.**
Cada empleado tiene un interruptor. Al apagarlo, el empleado pasa a **Inactivo** y su tarjeta se ve más apagada (gris y semitransparente), para distinguirlo de un vistazo.

**3. Permite registrar empleados nuevos.**
Con el botón **Nuevo empleado** se abre un formulario con:

- Nombre completo y puesto (se escriben).
- Área: Tecnología, Recursos Humanos, Finanzas, Operaciones, Ventas o Administración.
- Género: Masculino, Femenino u Otro.
- Fecha de entrada y fecha de nacimiento (se eligen en un calendario).

Si falta algún dato, el formulario avisa qué falta y no guarda nada. También impide fechas que no tienen sentido, como una fecha de entrada en el futuro o una fecha de nacimiento posterior a la de entrada.

**4. Confirma el registro.**
Cuando el registro sale bien aparece la pantalla **Empleado registrado correctamente**. Con el botón **Regresar a empleados** se vuelve a la lista, donde el empleado nuevo ya aparece y los totales se actualizan solos.

> **Importante:** los datos se guardan solo mientras la aplicación está abierta. Al cerrarla, vuelve a empezar con los cinco empleados de ejemplo. El examen pedía usar datos de ejemplo, sin base de datos ni internet.

## ¿Cómo se ejecuta?

Se necesita tener instalado **Flutter 3.41.6** (incluye Dart 3.11.4). Desde la carpeta del proyecto:

```bash
flutter pub get
flutter run
```

El primer comando descarga lo que el proyecto necesita; el segundo abre la aplicación. Para abrirla en el navegador: `flutter run -d chrome`.

## ¿Cómo está organizado por dentro?

El código está separado en **tres partes**, cada una con un trabajo distinto. Así, si una parte cambia, las demás no se ven afectadas. Esta forma de organizarlo se llama **Clean Architecture**.

| Parte | Qué hace | Ejemplo cotidiano |
|---|---|---|
| **Pantallas** (presentación) | Lo que ve y toca el usuario: la lista, el formulario y la confirmación. | El mostrador de una tienda. |
| **Reglas** (dominio) | Define qué es un empleado y qué se puede hacer con él (consultar, registrar, activar o desactivar). | El reglamento de la tienda. |
| **Datos** | Guarda y entrega la información de los empleados. Hoy los guarda en memoria; mañana podría ser una base de datos sin cambiar las pantallas. | La bodega. |

Entre las pantallas y los datos hay un **coordinador** llamado `EmployeeCubit`. Recibe lo que pide la pantalla (por ejemplo, "registra a este empleado"), se lo pide a la parte de datos y avisa a todas las pantallas del resultado. Como hay **un solo coordinador** para toda la aplicación, la lista y el formulario siempre muestran la misma información.

```text
Pantalla  ──►  Coordinador (EmployeeCubit)  ──►  Datos (empleados en memoria)
    ▲                    │
    └──── se actualiza ──┘
```

Las carpetas del código siguen esa misma división: `presentation` (pantallas), `domain` (reglas) y `data` (datos), dentro de `lib/features/employees`.

## Herramientas que usa

| Herramienta | Para qué sirve |
|---|---|
| **Flutter** 3.41.6 | Crear la aplicación para celular, web y escritorio con un solo código. |
| **flutter_bloc** (Cubit) | Organizar el coordinador que mantiene la información al día en todas las pantallas. |
| **equatable** | Comparar fácilmente si dos datos son iguales. |
| **flutter_localizations** | Mostrar la aplicación y el calendario en español. |
| **bloc_test** y **mocktail** | Escribir pruebas automáticas (no forman parte de la aplicación final). |

## ¿Cómo sabemos que funciona?

El proyecto incluye **105 pruebas automáticas** que revisan, por ejemplo, que el formulario no deje registrar con datos incompletos, que el empleado nuevo aparezca en la lista y que los totales se calculen bien. Se ejecutan con:

```bash
flutter test
```

Para el detalle técnico de la arquitectura, ver [docs/architecture.md](docs/architecture.md).
