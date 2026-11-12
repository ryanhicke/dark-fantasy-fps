# Dark Fantasy FPS

A just-for-fun, retro first-person shooter in the spirit of the 90s classics.
You fight through eight linear levels with swords, axes, bows, thrown
franciscas and magic (fireballs, lightning, healing and armor spells).

It's built to run on modest hardware: the 3D view renders at a low internal
resolution (640x360 by default) and is upscaled with crisp pixels, enemies and
pickups are 2D sprites, and lighting is kept simple. It should hold 60 FPS on
a laptop with integrated graphics.

## Requirements

- **[Godot 4.7](https://godotengine.org/download)** (the standard build, not
  the .NET one). The project uses the Compatibility (OpenGL) renderer and the
  built-in Jolt physics, so no extra setup is needed.
- Windows is the tested platform. Linux and macOS should work but haven't
  been tried yet.

Everything else is in the repo: the GUT and FuncGodot addons live in
`addons/`.

## Run it from the editor

1. Clone the repo:

   ```bash
   git clone https://github.com/ryanhicke/dark-fantasy-fps.git
   ```

2. Open Godot, choose **Import**, and select `project.godot` in the cloned
   folder.
3. The first time you open it, Godot imports all the assets. Wait for that to
   finish (watch the progress bar at the bottom).
4. Press **F5** (or the Play button, top right) to run from Level 1.

You can also run it from a terminal without opening the editor:

```bash
godot --path .
```

(Replace `godot` with the path to your Godot executable.)

## Build a standalone executable

The repo includes a **Windows Desktop** export preset that writes to
`builds/windows/`.

1. Install the export templates once: in the editor, open
   **Editor > Manage Export Templates** and click **Download and Install**.
   The templates must match your Godot version exactly (4.7).
2. Open **Project > Export**, select **Windows Desktop**, and click
   **Export Project**. Untick **Export With Debug** for a release build.
3. Copy both `dark-fantasy-fps.exe` and `dark-fantasy-fps.pck` from
   `builds/windows/` to wherever you want. They need to stay side by side.

Or build from the command line (export templates still need to be installed):

```bash
mkdir -p builds/windows
godot --headless --path . --export-release "Windows Desktop" builds/windows/dark-fantasy-fps.exe
```

The preset leaves out the unit tests and the GUT addon, so they aren't in the
build. `builds/` is git-ignored.

For Linux or macOS, add a preset for that platform under **Project > Export**.
The rest of the steps are the same.

## Controls

| Action | Key |
| --- | --- |
| Move | W A S D |
| Look | Mouse |
| Jump | Space |
| Attack / cast | Left mouse button |
| Use (doors, levers) | E |
| Select weapon | 1-9 |
| Next / previous weapon | Mouse wheel |
| Respawn after dying | Enter |
| Release the mouse | Esc |

Debug builds (running from the editor, or an export with debug) also have
some developer keys:

| Key | Effect |
| --- | --- |
| F2 | Cycle the internal resolution scale |
| F3 | Toggle the debug overlay |
| F4 | Give every weapon and full ammo |

## Running the tests

Logic-heavy systems (damage, inventory, level progression, and so on) have
unit tests written with [GUT](https://github.com/bitwes/Gut). Run them
headless with:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Or open the **GUT** panel at the bottom of the editor and click **Run All**.

## Editing levels

Levels are built in [TrenchBroom](https://trenchbroom.github.io/) and
imported with the [FuncGodot](https://github.com/func-godot/func_godot_plugin)
plugin. The `.map` source files are in `assets/maps/`. Each level scene in
`levels/` has a FuncGodot map node that points at its `.map` file. Select that
node and click **Build** in the toolbar to re-import after editing the map.

## Project layout

```
core/      autoloads: game state, event bus, saving, audio, settings
player/    player controller, camera, inventory
weapons/   melee, ranged and spell weapons
spells/    spell data and projectile scenes
enemies/   enemy base class, state machine and individual enemies
levels/    level scenes and map entities
ui/        HUD, intermission screen
assets/    sprites, textures, maps, and the scripts that generate the sprites
tests/     GUT unit tests
docs/      story, enemy and weapon notes, and the placeholder list
```

## Art and credits

- Most sprites are procedural pixel art drawn by Python scripts in
  `assets/source/sprites/`. They were written with AI assistance (Claude).
  `docs/placeholders.md` lists every placeholder and AI-generated asset.
- Level textures are currently tinted versions of FuncGodot's default
  checker texture.
- [GUT](https://github.com/bitwes/Gut) (MIT) and
  [FuncGodot](https://github.com/func-godot/func_godot_plugin) (MIT) are
  bundled in `addons/` under their own licenses.

## License

The project is released under the [MIT License](LICENSE). The addons in
`addons/` keep their own licenses.
