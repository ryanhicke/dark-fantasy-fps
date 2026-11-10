# CLAUDE.md

Project guidance for Claude Code. Read this fully before making changes.

## Project overview

A dark fantasy first-person shooter in the spirit of **Hexen: Beyond Heretic**, **Doom**, and **Quake**. The player fights with melee weapons (swords, axes), ranged weapons (bows, franciscas), and magic (protection spells like healing and armor, attack spells like fireball and lightning).

- **Structure:** Doom-style **linear sequence of levels**. No hubs. No returning to finished levels.
- **Target platform:** PC (Windows first, then Linux/Mac), sold on Steam.
- **Target hardware:** Basic laptops with **integrated graphics only** (no dedicated GPU). Performance is a hard requirement, not a nice-to-have.
- **Team:** Solo developer working with Claude Code. Claude cannot playtest, so the developer is the feedback loop.

## Tech stack

- **Engine:** Godot 4.x (stable)
- **Renderer:** Compatibility (OpenGL). Do not switch to Forward+ or Mobile.
- **Language:** GDScript with **static typing everywhere**
- **Level editor:** TrenchBroom, imported with the FuncGodot plugin
- **Testing:** GUT (Godot Unit Test) for logic-heavy systems
- **Steam integration:** GodotSteam (added later, keep it isolated behind a wrapper)

## Hard performance constraints

These apply to every change. If a request conflicts with them, say so before implementing.

1. The 3D view renders into a low-resolution `SubViewport` (default 640x360) that is upscaled with nearest-neighbor filtering. The resolution scale must be user-configurable.
2. Enemies, pickups, and decorations are **billboarded 2D sprites**, not 3D models. Weapon view models are sprites or very low-poly meshes.
3. Textures are small (64x64 to 128x128, power-of-two) with nearest-neighbor filtering and no mipmaps unless justified.
4. **No custom heavy shaders.** No SSAO, SSR, volumetrics, glow, real-time global illumination, or high-quality shadows. Prefer baked or flat lighting.
5. Limit real-time lights. Fake glow for fireballs and torches with sprites and emissive materials, not dynamic lights.
6. Avoid per-frame allocations and per-frame `get_node()` or group lookups. Cache node references in `@onready` variables.
7. Use object pooling for projectiles, impact effects, and gibs if spawn counts get high.
8. Keep physics simple: use simple collision shapes and avoid per-frame raycasts from many enemies at once (stagger AI updates).

Target: stable 60 FPS at 720p-equivalent on a typical integrated-graphics laptop.

## Directory structure

```
res://
  core/        # autoloads: GameState, EventBus, SaveManager, AudioManager
  player/      # controller, camera, inventory, spell caster
  weapons/     # base Weapon class; Melee, Ranged, Spell subclasses
  spells/      # SpellData resources + projectile/effect scenes
  enemies/     # base Enemy + state machine + individual enemies
  levels/      # level_01.tscn, level_02.tscn, ... plus the level list resource
  ui/          # HUD, menus, intermission/stats screen
  assets/      # art, audio, maps (source files stay outside the repo or in /source)
  tests/       # GUT tests
```

Keep scenes and their scripts together in the same folder. Do not create new top-level folders without asking.

## Architecture

### Autoloads (singletons)

- **GameState:** holds the ordered level list, current level index, and the player state bundle that carries between levels (health, armor, mana, owned weapons, ammo, permanent upgrades). Handles level loading and the intermission flow.
- **EventBus:** global signals for decoupled communication (e.g. `player_damaged`, `enemy_killed`, `secret_found`, `level_completed`). Prefer the bus over direct node references across systems.
- **SaveManager:** quicksave/quickload. Serializes the current level plus the player state bundle. Because levels are linear and never revisited, there is **no per-level persistence between levels**.
- **AudioManager:** music and SFX playback, bus volumes, and pooled `AudioStreamPlayer` nodes.

### Level flow

1. `GameState` holds an ordered list of level scenes (a `LevelList` resource).
2. The player reaches the exit, `level_completed` fires, and the intermission screen shows kills, secrets, and time.
3. `GameState` stores the player bundle, loads the next level, and restores the bundle.
4. Keys and locked doors are **local to a single level** and reset when the level changes.
5. Support a "pistol start" (default equipment) for any level. The player state is a small data bundle, so this should be trivial.

### Data-driven design

- Weapons and spells are defined as **`Resource` files** (`WeaponData`, `SpellData`) with damage, mana/ammo cost, cooldown, projectile scene, sounds, and so on. Adding a new spell or weapon should be mostly data, with new code only for genuinely new behavior.
- Enemy stats (health, speed, damage, sight range, pain chance) live in an `EnemyData` resource.

### Class hierarchy

- `Weapon` (base) with subclasses `MeleeWeapon`, `RangedWeapon`, `SpellWeapon`
- `Enemy` (base) with a simple state machine: `IDLE`, `CHASE`, `ATTACK`, `PAIN`, `DIE`. Doom-style AI is deliberately simple: sight, wake-up, chase, attack, occasional pain stagger.
- `Projectile` (base) for fireballs, arrows, and so on, with per-type subclasses only where behavior differs.

### Damage

All damage flows through a single `HealthComponent` (or equivalent) with `take_damage(amount, type, source)`. Damage types should be enumerated (physical, fire, lightning, and so on) so armor and resistances can work later.

## Code conventions

- **Static typing is mandatory.** Type all variables, parameters, and return values. Use `class_name` for reusable classes.
- Naming: `snake_case` for variables, functions, and files; `PascalCase` for classes and nodes; `UPPER_SNAKE_CASE` for constants and enum values.
- Signals are named in past tense (`health_changed`, `enemy_died`).
- Use `@export` for tunable values so they can be adjusted in the editor.
- Prefer composition and small scenes over deep inheritance trees.
- Keep scripts short and single-purpose. If a script passes ~300 lines, consider splitting it.
- No magic numbers: use constants or exported variables.
- Comment the **why**, not the what.
- Use `_physics_process` for movement and physics and `_process` for visuals and UI only.
- Respect Godot's scene tree: use signals up, calls down.

## Working agreements for Claude Code

1. **Work in small, testable increments.** One system at a time. After each one, tell me exactly how to test it in the editor (which scene to open, what to press, what I should see).
2. **Plan first for anything non-trivial.** For new systems, propose the approach briefly and wait for confirmation before writing a lot of code.
3. **Do not touch** the `.godot/` folder, `*.import` files, or binary assets. Do not generate or modify image, audio, or model files.
4. Edit `.tscn` and `.tres` files carefully. They are text but sensitive to syntax and unique resource IDs. Prefer creating scenes through scripts or minimal, well-formed edits, and tell me to reopen the editor afterward if needed.
5. Do not install new addons or dependencies without asking. List the license and size impact first.
6. Do not refactor unrelated code while working on a task. Mention improvements instead of silently making them.
7. If a request conflicts with the performance constraints or this document, say so before proceeding.
8. If you are unsure how something behaves in Godot 4, say so rather than guessing. Check the official docs when possible. Do not use Godot 3 syntax or APIs (for example, use `@export`, not `export`; `await`, not `yield`).
9. Commit-friendly changes: keep each task focused so I can review the diff and commit it on its own.

## Useful commands

```bash
# Check that the project loads and scripts parse without errors (headless)
C:\GoDot\Godot_v4.7.2-stable_win64.exe --headless --path . --quit

# Run GUT tests headless
C:\GoDot\Godot_v4.7.2-stable_win64.exe --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# Run the project
C:\GoDot\Godot_v4.7.2-stable_win64.exe --path .
```

(Adjust the `godot` executable name or path for the local install.)

## Git

- Git from day one. `.gitignore` must exclude `.godot/`, export builds, and any `.import` cache folders not needed for the repo.
- Small commits with clear messages. Never rewrite published history.

## Testing

- Write GUT tests for pure-logic systems: damage calculation, inventory and ammo, player state bundle save/restore, level list progression, spell cost and cooldown.
- Gameplay feel (movement, weapon feedback, AI behavior) is tested manually by me. Do not try to unit test feel.

## Assets and licensing

- Anything that ships on Steam must have a license that allows commercial use. Prefer CC0 or assets I own.
- When suggesting or referencing a third-party asset, state its license. If unsure, say so.
- Placeholder art and audio are fine during development, but keep a list of placeholders to replace before release in `docs/placeholders.md`.
- If any AI-generated assets are ever used, they must be tracked, since Steam requires disclosure.

## Current scope: vertical slice

Build in this order. Do not move to the next item until the current one works and I confirm.

1. Player controller (movement, mouse look, head bob optional)
2. One melee weapon and one ranged weapon
3. One enemy with the basic state machine
4. One attack spell (fireball)
5. A small test level built in TrenchBroom with a door, a key, and an exit
6. Level transition and intermission screen
7. Low-resolution `SubViewport` rendering with a resolution scale option
8. Test on a real integrated-graphics laptop

Planned later (not now): more weapons, healing and armor spells, lightning, more enemies, secrets, quicksave/quickload, full level set, menus and options, Steam integration, controller support.

## Out of scope (do not build unless I ask)

- Hub-based levels or per-level state persistence
- Multiplayer
- Procedural level generation
- Heavy post-processing or advanced lighting
- Open-world or large streaming levels