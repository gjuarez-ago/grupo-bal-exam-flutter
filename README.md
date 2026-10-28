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

## ¿Qué hay en cada carpeta?

Todo el código de la aplicación está en la carpeta `lib`:

```text
lib/
├── main.dart                  Punto de arranque de la aplicación
├── app.dart                   Configuración general: colores, idioma español y el coordinador
├── core/                      Cosas que usa toda la aplicación
│   ├── theme/                 Colores y estilo visual
│   └── utils/                 Herramientas pequeñas, como el formato de fechas
├── shared/                    Piezas visuales que podrían compartir varias secciones
└── features/                  Una carpeta por cada sección de la aplicación
    └── employees/             Todo lo relacionado con empleados
        ├── domain/            Reglas
        │   ├── entities/          Qué datos tiene un empleado y la lista de áreas
        │   └── repositories/      Qué se puede hacer con los empleados (la «lista de servicios»)
        ├── data/              Datos
        │   ├── datasources/       Dónde se guardan los empleados (hoy, en memoria) y los 5 de ejemplo
        │   └── repositories/      Cómo se cumple cada servicio usando ese almacén
        └── presentation/      Pantallas
            ├── cubit/             El coordinador y la información que comparte con las pantallas
            ├── pages/             Las tres pantallas: lista, formulario y confirmación
            ├── widgets/           Piezas de pantalla: la tarjeta del empleado, el interruptor, los totales
            └── validators/        Las revisiones del formulario (campos vacíos, fechas incorrectas)
```

**¿Por qué así?**

- **Cada cosa tiene un solo lugar.** Si hay que cambiar cómo se ve la tarjeta de un empleado, se va a `widgets`; si cambia una regla del formulario, a `validators`. No hay que buscar por todo el proyecto.
- **Lo que se agrupa es la sección, no el tipo de archivo.** Todo lo de empleados está junto en `features/employees`, en lugar de mezclar en una sola carpeta todas las pantallas de todas las secciones.
- **Las reglas no dependen de nada más.** La carpeta `domain` no sabe cómo se ven las pantallas ni dónde se guardan los datos; por eso es la parte más estable.

## ¿Cómo puede crecer?

La aplicación está pensada para crecer sin tener que rehacer lo que ya funciona:

- **Agregar una sección nueva** (por ejemplo, vacaciones o departamentos): se crea otra carpeta dentro de `features`, con las mismas tres partes (`domain`, `data` y `presentation`). La sección de empleados no se toca.
- **Pasar de datos de ejemplo a una base de datos o internet:** solo cambia la carpeta `data`. Se escribe un nuevo «almacén» que cumpla la misma lista de servicios y se conecta en `main.dart`. Las pantallas y las reglas siguen igual, porque nunca supieron de dónde venían los datos.
- **Reutilizar piezas visuales:** si una pieza, como un botón o un aviso, empieza a usarse en varias secciones, se mueve a `shared` para no repetirla.
- **Cambiar el aspecto de toda la app:** los colores y estilos están centralizados en `core/theme`; se ajustan en un solo lugar.

## Herramientas que usa

| Herramienta | Para qué sirve |
|---|---|
| **Flutter** 3.41.6 | Crear la aplicación para celular, web y escritorio con un solo código. |
| **flutter_bloc** (Cubit) | Organizar el coordinador que mantiene la información al día en todas las pantallas. |
| **equatable** | Comparar fácilmente si dos datos son iguales. |
| **flutter_localizations** | Mostrar la aplicación y el calendario en español. |

Para el detalle técnico de la arquitectura, ver [docs/architecture.md](docs/architecture.md).
