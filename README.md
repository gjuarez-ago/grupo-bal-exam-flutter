# employee_management

Aplicación Flutter para la administración de empleados, desarrollada como examen técnico.

## Objetivo

Construir una aplicación de gestión de empleados organizada con Clean Architecture, manejo de estado mediante Cubit (`flutter_bloc`), datos mock y pruebas automatizadas, estructurada por módulos para que pueda crecer sin acumular archivos en carpetas globales.

## Estado actual

**Fase 1: inicialización.**

- Proyecto generado con `flutter create`.
- Estructura de carpetas modular definida.
- Arranque mínimo de la aplicación (`main.dart` → `app.dart`).

Todavía **no** se ha implementado la funcionalidad de empleados ni se han agregado dependencias de terceros (`flutter_bloc`, `equatable`, etc.).

## Requisitos previos

- Flutter SDK (canal stable) — versión utilizada: **Flutter 3.41.6**
- Dart SDK — versión utilizada: **Dart 3.11.4**
- Git
- Un emulador, dispositivo físico o navegador compatible con Flutter

Comprueba tu entorno con:

```bash
flutter doctor
```

## Instalación y ejecución

```bash
# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run
```

## Verificación

```bash
dart format lib test
flutter analyze
flutter test
```

## Estructura prevista

```text
lib/
├── core/            # Recursos transversales (tema, utilidades)
├── shared/          # Componentes compartidos entre módulos (widgets)
├── features/
│   └── employees/   # Módulo de empleados
│       ├── domain/        # Entidades y contratos de repositorio
│       ├── data/          # Fuentes de datos e implementaciones de repositorio
│       └── presentation/  # Cubit, páginas y widgets
├── app.dart         # Widget raíz de la aplicación
└── main.dart        # Punto de entrada
```

Las carpetas vacías contienen un archivo `.gitkeep` para que Git las conserve; se eliminará cuando la carpeta tenga contenido real.

Consulta [docs/architecture.md](docs/architecture.md) para más detalle sobre la arquitectura prevista.
