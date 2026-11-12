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
| Warhammer view model | `weapons/warhammer/warhammer.tscn` | `BoxMesh` haft and head; heavier, slower swing | Warhammer sprite or low-poly mesh with swing animation |
| Francisca view model and projectile | `weapons/francisca/francisca.tscn`, `francisca_projectile.tscn` | `BoxMesh` haft and blade; the thrown axe tumbles end over end | Axe sprite (spinning frames) or low-poly mesh |
| Magic wand view model | `weapons/magic_wand/magic_wand.tscn` | `BoxMesh` wand with a pale-blue tip; cast is a forward thrust | Wand sprite or low-poly mesh with cast animation |
| Healing wand view model | `weapons/healing_wand/healing_wand.tscn` | `BoxMesh` wand with a green tip | Wand sprite or low-poly mesh with cast animation |
| Armor spell view model | `weapons/armor_spell/armor_spell.tscn` | `BoxMesh` amulet plate with a gold gem | Amulet/rune sprite with cast animation |
| Lightning view model | `weapons/lightning/lightning.tscn` | Pale-blue `BoxMesh` crystal shard | Crackling crystal or hand sprite with cast animation |
| Lightning bolt | `spells/lightning/lightning_bolt.tscn` | Five thin unshaded `BoxMesh` segments with random joints, thinning out over 0.15 s; pale screen flash | Bolt sprite strip or stretched quad texture |
| Crystal obelisks | `levels/entities/crystal_obelisk.tscn` | Tinted `BoxMesh` crystal; weapon icon is a `Label3D` word (HAMMER/FIRE/AXE/MISSILE) | Crystal sprite or low-poly mesh, weapon icons, shatter effect and SFX, and a 'wrong weapon' clink |
| Fire staff view model | `weapons/fire_staff/fire_staff.tscn` | `BoxMesh` shaft and orange orb; cast is a forward thrust | Staff sprite or low-poly mesh with cast animation |
| Fireball projectile | `spells/fireball/fireball.tscn` | Flat orange billboarded `QuadMesh` | Animated fireball sprite |
| Fireball explosion | `spells/fireball/fireball_explosion.tscn` | Growing, fading orange billboarded `QuadMesh` | Explosion sprite animation |
| Spell sounds | — | None (silent) | Fireball cast, flight loop, explosion SFX |
| Weapon pickups | `levels/entities/weapon_pickup.tscn`, `weapon_*.tscn` | Flat tinted billboarded `QuadMesh` per weapon | Weapon pickup sprites |
| Ammo and mana pickups | `levels/entities/ammo_pickup.tscn`, `ammo_*.tscn` | Small flat tinted billboarded `QuadMesh` (arrows, franciscas, mana) | Arrow bundle, axe stack, mana crystal sprites |
| Health pickups | `levels/entities/health_pickup.tscn`, `health_small.tscn`, `health_large.tscn` | Small flat tinted billboarded `QuadMesh` (light red draught, dark red potion) | Healing draught and healing potion sprites |
| Pickup sounds | — | None (silent) | Weapon, ammo, and health pickup SFX |
| Key pickup | `levels/entities/key_pickup.tscn` | Small tinted billboarded `QuadMesh` | Key sprites (gold, silver, bone) |
| Map textures | `assets/maps/test_map.map` (`base/wall`, `base/floor`, `base/ceiling`, `base/door`, `base/door_gold`) | None: FuncGodot default checker | 64x64 or 128x128 PNGs in `assets/textures/base/` |
| Level 1 textures | `assets/maps/level_01.map`, materials in `assets/textures/{forest,cave,wood,door,gold}/*.tres` | Tinted FuncGodot default checker (bright forest, dark cave tints fake the lack of light) | 64x64 or 128x128 PNGs: forest ground/cliff, cave rock/floor/dirt/straw/ceiling, wood planks/crate/cart/fence/door/strongbox, grain sack, gold door, coins |
| Level 1 props and note | `assets/maps/level_01.map` | Plain brush boxes for the cart, grain crates, fences, strongbox, coin pile; no readable note (the exit trigger sits on the table) | Prop sprites or detailed brushes, and a readable note pickup |
| Level 2 textures | `assets/maps/level_02.map`, materials in `assets/textures/outpost/*.tres`, `door/silver.tres` | Tinted FuncGodot default checker | 64x64 or 128x128 PNGs: mud, palisade logs, gate, watchtower, straw, plank wall/floor, thatch, stone floor, forge, anvil, bed, black wax, silver door |
| Level 2 props and purse | `assets/maps/level_02.map` | Plain brush boxes for watchtowers (no ladders, archers unreachable), wagons, stalls, forge, anvil, beds, footlocker, tables, treasure; no purse item (the exit trigger sits on the treasury table) | Prop sprites or detailed brushes, climbable towers if wanted, and a black-wax purse pickup |
| Keys / message text | `ui/hud.tscn` | Default-font `Label`s ("Keys: Gold", "Picked up the Gold Key") | Styled HUD and key icons |
| Door and pickup sounds | — | None (silent) | Door open/close/locked, key pickup SFX |
| Bandit sprite (**AI-generated**) | `assets/sprites/enemies/bandit_sheet.png`, made by `assets/source/sprites/bandit.py` | Claude-authored procedural pixel art (front-facing only: idle, 4-frame walk, windup, swing, pain, 4-frame death). **Must be disclosed on Steam as AI-generated if it ships.** Disguised variants share the sheet | Hand-made sprite sheet with 8 rotations, or keep and disclose |
| Bandit archer sprite (**AI-generated**) | `assets/sprites/enemies/bandit_archer_sheet.png`, made by `assets/source/sprites/bandit_archer.py` | Claude-authored procedural pixel art (front-facing only: idle, 4-frame walk, draw, release, pain, 4-frame death). Still fires the player's placeholder arrow. **Must be disclosed on Steam as AI-generated if it ships.** Disguised variants share the sheet | Hand-made sprite sheet with 8 rotations, or keep and disclose |
| Armored mercenary sprite (**AI-generated**) | `assets/sprites/enemies/armored_mercenary_sheet.png`, made by `assets/source/sprites/armored_mercenary.py` | Claude-authored procedural pixel art, front-facing only: chainmail coif, plate cuirass, blonde goatee, two-handed warhammer (idle, 4-frame walk, hammer windup, smash, pain, 4-frame death). Disguised variant shares the sheet. **Must be disclosed on Steam as AI-generated if it ships.** | Hand-made sprite sheet with 8 rotations, or keep and disclose |
| Werewolf sprite (**AI-generated**) | `assets/sprites/enemies/werewolf_sheet.png`, made by `assets/source/sprites/werewolf.py` | Claude-authored procedural pixel art of a hunched dark-grey beast (front-facing only: idle, 4-frame run, rear-up windup, claw swipe, pain, 4-frame death). Disguised werewolves switch to it instantly on rising. **Must be disclosed on Steam as AI-generated if it ships.** | Hand-made sprite sheet with 8 rotations, plus a human-to-wolf transformation animation |
| Werewolf growl / howl | `EnemyData.alert_sound` on `enemies/werewolf/*.tres` | None (silent), so disguised werewolves are currently indistinguishable from humans | Growl for disguised wake-up (must be clearly different from the human alert), howl when rising |
| Skeleton sprite (**AI-generated**) | `assets/sprites/enemies/skeleton_sheet.png`, made by `assets/source/sprites/skeleton.py` | Claude-authored procedural pixel art, front-facing only: grave-stained, mossy bones, rusted horned helmet, femur club (idle, 4-frame walk, windup, swing, pain, death collapsing into a bone pile). Rising is still the quad scaling up from the floor. **Must be disclosed on Steam as AI-generated if it ships.** | Hand-made sheet with 8 rotations and a climb-out-of-the-ground animation (and dirt burst) |
| Apprentice wizard sprite (**AI-generated**) | `assets/sprites/enemies/apprentice_wizard_sheet.png`, made by `assets/source/sprites/apprentice_wizard.py` | Claude-authored procedural pixel art, front-facing only: brownish-grey hooded robe, faceless with glowing red eyes, potion belt (idle, 4-frame walk, fireball forming, cast, pain, 4-frame death). Still shoots the player's placeholder fireball. **Must be disclosed on Steam as AI-generated if it ships.** | Hand-made sprite sheet with 8 rotations, or keep and disclose |
| Melee demon sprite (**AI-generated**) | `assets/sprites/enemies/melee_demon_sheet.png`, made by `assets/source/sprites/melee_demon.py` | Claude-authored procedural pixel art, front-facing only: pink, muscular, large red horns, glowing white eyes, red claws on hands and goat feet (idle, 4-frame run, claws raised, rake, pain, 4-frame death). **Must be disclosed on Steam as AI-generated if it ships.** | Hand-made sprite sheet with 8 rotations, or keep and disclose |
| Imp sprite (**AI-generated**) | `assets/sprites/enemies/imp_sheet.png`, made by `assets/source/sprites/imp.py` | Claude-authored procedural pixel art, front-facing only: small blue demon, white horns, black goatee, floating on a violet magic disc instead of wings (idle, 4-frame hover, missile windup, throw, pain, death falling to the floor). **Must be disclosed on Steam as AI-generated if it ships.** | Hand-made sprite sheet with 8 rotations, or keep and disclose |
| Magic missile projectile | `spells/magic_missile/magic_missile.tscn` | Small flat pale-blue billboarded `QuadMesh` | Animated missile sprite with a short trail |
| Necromancer sprite (**AI-generated**) | `assets/sprites/enemies/necromancer_sheet.png`, made by `assets/source/sprites/necromancer.py` | Claude-authored procedural pixel art, front-facing only: black robes with the hood down, pointed black beard, skull medallion, green belt and shoes (idle, 4-frame walk, fireball raised, throw, pain, 4-frame death). No separate summon pose; summoned demons still rise by the quad scaling up. **Must be disclosed on Steam as AI-generated if it ships.** | Boss sheet with 8 rotations and a summon pose, summoning circle or dirt-burst effect |
| Great demon sprite (**AI-generated**) | `assets/sprites/enemies/great_demon_sheet.png`, made by `assets/source/sprites/great_demon.py` | Claude-authored procedural pixel art, front-facing only: grey rock demon with glowing yellow cracks and a broken crown, 6 m quad (idle, 4-frame breathing loop, fire gathering in its maw, blast, pain, death crumbling to rubble). The obelisk cracks of light are still the four pale-yellow `Sprite/Crack1..4` quads, positioned to land on its torso and thigh. **Must be disclosed on Steam as AI-generated if it ships.** | Hand-made layered boss sprites: body plus crack-of-light overlays drawn on top (CLAUDE.md rule 2) |
| Great demon roar | `GreatDemonPhases.roar_sound` | None (silent); only a flash | Roar SFX (and optional screen shake) on each destroyed obelisk |
| Enemy sounds | `EnemyData.alert_sound` (bandit, archer, mercenary) | None (silent); `Voice` player exists but no streams assigned | Alert/sight, attack, pain, death SFX per enemy; armor clank on resisted hits |
| Health counter | `ui/hud.tscn` | Default-font `Label` ("Health: 100") | Styled HUD |
| Armor spell screen tint | `ui/hud.tscn` (`ArmorTint`) | Flat gold `ColorRect`; blinks in the last second | Keep or restyle (gold/silver frame) |
| Heal flash | `ui/hud.gd` (`heal_flash_color`) | Green version of the damage flash | Keep or restyle |
| Self-spell sounds | — | None (silent) | Heal cast, armor cast, armor fading SFX |
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
| Main menu Enemy Gallery / Great Demon Arena buttons (debug builds only) | `ui/main_menu.tscn`, `ui/main_menu.gd` |
| F4 give all weapons and full ammo | `player/dev_cheats.gd` (debug builds only) |
| F2 render scale cycle | `ui/game_view.gd` (debug builds only) |
| F3 FPS / resolution readout | `ui/hud.gd`, `DebugLabel` in `ui/hud.tscn` (debug builds only) |
| Test level geometry, colors, and green exit pad | `levels/test_level.tscn` (level 2 in `levels/level_list.tres`) |
| Enemy gallery (one walled bay per enemy type; not in the level list, run with F6) | `levels/enemy_gallery.tscn` |
| Great demon arena | `levels/great_demon_arena.tscn` |
| Starter test map | `levels/test_map/`, `assets/maps/test_map.map` |
