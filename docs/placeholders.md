# Placeholders to replace before release

Everything here is temporary and must be replaced (or confirmed as final)
before shipping. Note the license of every replacement asset.

| Item | Where | Current placeholder | Replace with |
|---|---|---|---|
| Sword view model | `weapons/sword/sword.tscn` | Three Godot `BoxMesh` primitives, flat colors | Sword sprite or very low-poly mesh with swing animation |
| Bow view model | `weapons/bow/bow.tscn` | `BoxMesh` limb, string, and nocked arrow; draw moves string+arrow back | Bow sprite or low-poly mesh with draw/release animation |
| Arrow projectile | `weapons/arrow/arrow.tscn` | `BoxMesh` shaft and fletching | Arrow sprite or low-poly mesh |
| Ammo counter | `ui/hud.tscn` | Default-font `Label` ("Arrows: 50") | Styled HUD |
| Crosshair | `ui/hud.tscn` | Two `ColorRect`s | Final crosshair art (or keep if it fits the style) |
| Weapon sounds | — | None (silent) | Sword swing/hit, bow draw/release, arrow impact SFX |
| Fire staff view model | `weapons/fire_staff/fire_staff.tscn` | `BoxMesh` shaft and orange orb; cast is a forward thrust | Staff sprite or low-poly mesh with cast animation |
| Fireball projectile | `spells/fireball/fireball.tscn` | Flat orange billboarded `QuadMesh` | Animated fireball sprite |
| Fireball explosion | `spells/fireball/fireball_explosion.tscn` | Growing, fading orange billboarded `QuadMesh` | Explosion sprite animation |
| Spell sounds | — | None (silent) | Fireball cast, flight loop, explosion SFX |
| Key pickup | `levels/entities/key_pickup.tscn` | Small tinted billboarded `QuadMesh` | Key sprites (gold, silver, bone) |
| Map textures | `assets/maps/test_map.map` (`base/wall`, `base/floor`, `base/ceiling`, `base/door`, `base/door_gold`) | None: FuncGodot default checker | 64x64 or 128x128 PNGs in `assets/textures/base/` |
| Keys / message text | `ui/hud.tscn` | Default-font `Label`s ("Keys: Gold", "Picked up the Gold Key") | Styled HUD and key icons |
| Door and pickup sounds | — | None (silent) | Door open/close/locked, key pickup SFX |
| Bandit sprite | `enemies/bandit/bandit.tscn` | Brown flat-color billboarded `QuadMesh`; color changes for windup/pain, squashed quad for corpse | Sprite sheet (idle/walk/attack/pain/death frames) |
| Bandit archer sprite | `enemies/bandit_archer/bandit_archer.tscn` | Green flat-color billboarded `QuadMesh` (same color cues as the bandit); fires the player's placeholder arrow | Sprite sheet (idle/walk/draw/shoot/pain/death frames) |
| Armored mercenary sprite | `enemies/armored_mercenary/armored_mercenary.tscn` | Steel-gray, slightly wider flat-color billboarded `QuadMesh` (same color cues) | Sprite sheet (idle/walk/attack/pain/death frames) |
| Enemy sounds | `EnemyData.alert_sound` (bandit, archer, mercenary) | None (silent); `Voice` player exists but no streams assigned | Alert/sight, attack, pain, death SFX per enemy; armor clank on resisted hits |
| Health counter | `ui/hud.tscn` | Default-font `Label` ("Health: 100") | Styled HUD |
| Damage flash | `ui/hud.tscn` | Full-screen red `ColorRect` fade | Keep or restyle |
| Death prompt | `ui/hud.tscn` | Default-font `Label` ("Hit Enter to respawn") | Proper death screen |
| Intermission screen | `ui/intermission.tscn` | Flat dark `ColorRect` with default-font stat `Label`s | Styled stats screen (background art, font, tally-up animation) |
| Intermission / level-end sounds | — | None (silent) | Exit, stat tally, and continue SFX |
| Level names | `levels/*.tscn` (`Level.display_name`) | Empty; falls back to the root node name ("Test Map") | Real level titles |
| HUD font | `ui/hud.tscn` (all labels) | Godot's default anti-aliased font, rendered at the low internal resolution; soft at 640x360, hard to read at 320x180 | Pixel font designed for ~360p (commercial-use license), with font AA off |
| Game title | `ui/main_menu.tscn` (`TitleLabel`) | Placeholder text "Dark Fantasy FPS" in the default font | Final game name and logo |
| Main and options menus | `ui/main_menu.tscn`, `ui/options_menu.tscn` | Flat dark `ColorRect` background, default Godot `Button` theme and font; highlight is the default focus outline | Menu background art, themed buttons/font, highlight style |
| Menu sounds | — | None (silent) | Move, select, and back SFX |

## Dev-only (not shipped, remove or exclude from release builds)

| Item | Where |
|---|---|
| Training dummy | `enemies/training_dummy/` |
| F2 render scale cycle | `ui/game_view.gd` (debug builds only) |
| F3 FPS / resolution readout | `ui/hud.gd`, `DebugLabel` in `ui/hud.tscn` (debug builds only) |
| Test level geometry, colors, and green exit pad | `levels/test_level.tscn` (level 2 in `levels/level_list.tres`) |
| Starter test map | `levels/test_map/`, `assets/maps/test_map.map` |
