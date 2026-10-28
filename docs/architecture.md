# Arquitectura prevista

> Este documento describe el **diseño previsto** del proyecto. En la fase actual (inicialización) solo existe la estructura de carpetas y un arranque mínimo; la funcionalidad de empleados todavía no se ha implementado.

## Enfoque

El proyecto seguirá Clean Architecture organizada por funcionalidades (*features*). Cada módulo agrupa sus propias capas, de modo que el código de una funcionalidad vive junto y no se dispersa en carpetas globales.

La dirección de las dependencias es:

```text
presentation  →  domain  ←  data
```

- `domain` no depende de Flutter ni de las otras capas.
- `data` implementa los contratos definidos en `domain`.
- `presentation` consume `domain` y gestiona el estado de la interfaz.

## Capas y carpetas

### `lib/core`

Recursos transversales a toda la aplicación, sin lógica de negocio de ningún módulo.

- `theme/`: configuración visual (colores, tipografía, tema).
- `utils/`: utilidades genéricas (formateo, validaciones comunes, constantes).

### `lib/shared`

Componentes reutilizables por más de un módulo.

- `widgets/`: widgets genéricos de interfaz.

### `lib/features/employees/domain`

Reglas de negocio y contratos del módulo de empleados.

- `entities/`: entidades de negocio.
- `repositories/`: interfaces abstractas de repositorio que la capa de datos debe implementar.

### `lib/features/employees/data`

Implementación del acceso a datos.

- `datasources/`: fuentes de datos (inicialmente datos mock en memoria).
- `repositories/`: implementaciones concretas de los contratos de `domain`.

### `lib/features/employees/presentation`

Interfaz de usuario y gestión de estado.

- `cubit/`: Cubit y estados (`flutter_bloc`).
- `pages/`: pantallas del módulo.
- `widgets/`: widgets específicos del módulo.

## Pruebas

Las pruebas automatizadas se ubicarán en `test/`, reflejando la estructura de `lib/` a medida que se implementen las capas.

## Dependencias previstas

En fases posteriores se incorporarán `flutter_bloc` (Cubit) y, si se requiere, `equatable`. En esta fase solo existen las dependencias estándar generadas por Flutter.
