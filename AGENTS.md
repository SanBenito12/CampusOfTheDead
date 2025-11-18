# Repository Guidelines

## Project Structure & Module Organization
- Godot 4 project. Entry: `project.godot` (main scene set in config).
- Key folders:
  - `scenes/` — Gameplay and UI scenes (e.g., `arena/`, `units/`, `weapons/`, `projectiles/`, `components/`).
  - `resources/` — Data `*.gd`/`*.tres` (e.g., `units/`, `items/`, `wave/`).
  - `assets/` — Art, audio, fonts (mirrors in‑game categories).
  - `autoload/` — Singletons (e.g., `global.gd`, `sound_manager.tscn`).
  - `shaders/`, `effects/`, `styles/` — Rendering, VFX, and theme assets.
  - `.godot/` — Editor cache; do not edit manually.

## Build, Test, and Development Commands
- Open editor: `godot4 -e --path .` (Windows: `Godot_v4.x.exe -e --path .`).
- Run game: `godot4 --path .` (uses `[application].run/main_scene`).
- Headless run (for CI/demos): `godot4 --headless --path .`.
- Export (after presets configured): `godot4 --headless --path . --export-release "Linux/X11" build/game.x86_64`.

## Coding Style & Naming Conventions
- Language: GDScript 4; indent 4 spaces; UTF‑8 (`.editorconfig`).
- Files and scenes: `snake_case` (e.g., `health_bar.tscn`, `spawner.gd`).
- Classes: `PascalCase` via `class_name` (e.g., `UnitStats`, `Projectile`).
- Signals/Globals: keep existing prefixes (e.g., `on_enemy_died`, `Global`).
- Node names in scene tree: `PascalCase` and descriptive.
- Keep logic in scripts under the scene they control; shared code in `scenes/components/` or `resources/`.

## Testing Guidelines
- No test suite present. Recommended: add GdUnit4 or GUT.
- Place tests under `tests/`; name files `*_test.gd` and mirror folder structure.
- Example run (addon‑dependent): `godot4 --headless --path . --test`.

## Commit & Pull Request Guidelines
- Use Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`.
- One change per PR; keep diffs focused. Reference issues.
- PR description: summary, rationale, and gameplay impact; add screenshots/GIFs for visual changes.
- Touch only necessary scenes/resources; avoid manual edits in `.godot/`.

## Security & Configuration Tips
- Do not commit secrets in resources or code.
- Changing autoloads? Update `[autoload]` in `project.godot` and verify order.
- Large assets: place under `assets/` with the existing category layout.
