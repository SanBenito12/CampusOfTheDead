# DompeGod — Curso Brotato (Godot 4)

Juego tipo arena inspirado en Brotato hecho con Godot 4.5. Este repositorio contiene escenas, scripts y recursos listos para abrirse en el editor y ejecutar.

## Requisitos
- Godot 4.5+ instalado y accesible como `godot4` en la terminal.
- Clonar o descargar este repo en tu equipo.

## Estructura del proyecto
- `project.godot` — Configuración del proyecto y escena principal.
- `scenes/` — Escenas de juego y UI (p. ej. `arena/`, `units/`, `weapons/`, `projectiles/`).
- `resources/` — Datos y recursos `.tres`/`.gd` (stats, oleadas, ítems).
- `assets/` — Sprites, audio y fuentes.
- `autoload/` — Singletons (p. ej. `autoload/global.gd`).
- `shaders/`, `effects/`, `styles/` — Sombreadores, VFX y estilos.
- `.godot/` — Caché del editor (no editar manualmente).

## Ejecutar en local
- Abrir el proyecto en el editor: `godot4 -e --path .`
- Ejecutar el juego directamente: `godot4 --path .`
- Modo headless (útil para CI): `godot4 --headless --path .`

## Controles (por defecto)
- Moverse: `W` `A` `S` `D`
- Dash: `Espacio`

## Exportar builds
1) Configura presets de exportación en el editor (Project > Export).
2) Exporta por CLI, por ejemplo Linux:  
   `godot4 --headless --path . --export-release "Linux/X11" build/game.x86_64`

## Contribución
- Revisa `AGENTS.md` para pautas de estructura, estilo y PRs.
- Sigue Conventional Commits (p. ej. `feat:`, `fix:`, `refactor:`).
- Evita tocar `.godot/` y limita cambios a escenas/recursos necesarios.

## Notas
- Si cambias autoloads, actualiza la sección `[autoload]` en `project.godot`.
- Assets grandes van en `assets/` bajo la categoría correspondiente.
