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
| Ghoul sprite | `enemies/ghoul/ghoul.tscn` | Flat-color billboarded `QuadMesh`; color changes for windup/pain, squashed quad for corpse | Sprite sheet (idle/walk/attack/pain/death frames) |
| Ghoul sounds | — | None (silent) | Sight, attack, pain, death SFX |
| Health counter | `ui/hud.tscn` | Default-font `Label` ("Health: 100") | Styled HUD |
| Damage flash | `ui/hud.tscn` | Full-screen red `ColorRect` fade | Keep or restyle |
| Death prompt | `ui/hud.tscn` | Default-font `Label` ("Hit Enter to respawn") | Proper death screen |

## Dev-only (not shipped, remove or exclude from release builds)

| Item | Where |
|---|---|
| Training dummy | `enemies/training_dummy/` |
| Test level geometry and colors | `levels/test_level.tscn` |
