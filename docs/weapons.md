# Weapons and Spells (working doc)

Status: **draft**. Same rules as [story.md](story.md): "Canon" is decided by the designer, "Ideas" are proposals.

Weapons and spells are data-driven (`WeaponData` / `SpellData` resources, see CLAUDE.md). This doc is the design source for those resources; numbers here are starting points for tuning, not final values.

## Overview

| Level | Weapon / spell | Type | Canon summary |
|-------|----------------|------|---------------|
| Start | Sword | Melee | Starting weapon, given by the captain of the guard |
| 1 | Bow | Ranged | Long range |
| 2 | Warhammer | Melee | Slower than the sword; same damage to unarmored enemies, more to armored |
| 3 | Francisca | Ranged (thrown) | Throwing axe thrown in an arc; stronger than the bow, shorter range; ammo is a stack of axes |
| 4 | Wand of healing | Spell (protection) | Heals 10 HP for 20 mana |
| 5 | Staff of fireball | Spell (attack) | Shoots fireballs |
| 6 | Wand of magic missile | Spell (attack) | Homing; weaker than the bow |
| 7 | Armor spell | Spell (protection) | Costs 75 mana; invulnerable for 5 seconds |
| 8 | Lightning | Spell (attack) | Only after the last obelisk falls; used to kill the great demon; can be used after the boss |

## General notes

- **Mana maxes out at 100** (Canon).
- **Mana is new in Level 4.** The player has never seen a mana bar before this point. *Idea:* hide the mana bar until the first spell is found, and place a mana pickup right next to the wand so the player learns how it works.
- **Each weapon solves a problem the game just introduced.** Where possible, let the player meet the problem first, then find the answer (see "Where it's found" for each weapon).

## Melee

### Sword
**Canon**
- Starting weapon. The captain of the guard gives it to you at the beginning of the game.
- Weak against armored mercenaries (Level 2).

**Ideas**
- The ending can mirror this: the mayor gives you the captain's own sword. See story.md, Ending.

### Warhammer
**Canon**
- Found in Level 2.
- **Slower** than the sword.
- Against unarmored enemies: **same damage** as the sword.
- Against armored enemies: **more damage** than the sword.
- Result: the sword is still the better choice against unarmored enemies (same damage, faster), and the warhammer is the answer to armor.
- Level 8: the only weapon that damages one of the 4 obelisks.

**Ideas**
- Where it's found: **after** the first armored mercenary, so the player feels the problem before getting the answer.

## Ranged

### Bow
**Canon**
- Found in Level 1.

**Ideas**
- The long-range option for the whole game. Weak against armored mercenaries.

### Francisca
**Canon**
- Found in Level 3. Replaces the crossbow from earlier drafts.
- A throwing axe: stronger than the bow, but shorter range.
- **Ammo is a stack of axes.** Throwing one uses one; you can't pick it back up. Refill from francisca pickups.
- **Thrown in an arc** (affected by gravity), unlike the bow's straight shot.
- Level 8: the only weapon that damages one of the 4 obelisks.
- Code: deals its own damage type, `THROWN` (not `SLASH` like the sword), so obelisks and resistances can tell the francisca and the sword apart.

**Ideas**
- Role: the bow is for long range; the francisca is for mid range when you need more damage. The arc also limits its useful range in a natural way.
- Spin the axe sprite in flight so the arc reads clearly.

## Spells

### Wand of healing
**Canon**
- Found in Level 4.
- Heals 10 HP for 20 mana.

**Ideas**
- Where it's found: on a dead priest or monk who tried to stop the necromancer before you.

### Staff of fireball
**Canon**
- Found in Level 5.
- Shoots fireballs (same attack the apprentice wizards use).
- Werewolves take extra damage from fire, which makes the staff a good choice in Levels 5–6.
- Level 8: the only weapon that damages one of the 4 obelisks.

**Ideas**
- Where it's found: taken from a dead or fleeing apprentice: "use their weapon against them".

### Wand of magic missile
**Canon**
- Found in Level 6.
- Homing missile, weaker than the bow.
- Level 8: the only weapon that damages one of the 4 obelisks.

**Ideas**
- Where it's found: **before** the necromancer boss fight, so the player has time to try it.
- Weaker but homing, so it's the right choice against fast flying imps in Level 7. Level 6 gives you the tool, Level 7 gives you the problem it solves. The imps also shoot magic missiles, a nice echo.
- Level 8: put its obelisk high up or behind a gap, where homing helps.

### Armor spell
**Canon**
- Found in Level 7.
- Costs **75 mana** (of a 100 maximum). Makes you invulnerable for 5 seconds.

**Ideas**
- At 75 of 100, it's a "save my life" button, not something to use in every fight: casting it leaves almost no mana for anything else.
- Feedback: a clear screen effect while active (a gold or silver tint on the HUD) and a sound when it runs out, so the player knows exactly when they can be hurt again.
- Where it's found: early enough in Level 7 to learn it. Right after it, put a fight that is easy to survive with 5 seconds of invulnerability (e.g. running through a corridor of fire or a crowd of imps).

### Lightning
**Canon**
- Found in Level 8, only after the last of the 4 obelisks is destroyed.
- You must use it to kill the great demon.
- It stays in your inventory and **can be used after the boss** (e.g. in a post-game or expansion levels).

**Ideas**
- Where it's found: when the 4th obelisk shatters, its crystal power gathers into a glowing pickup in the arena. The cracks of light in the demon's body all glow: "this is the moment" and "this is the weapon".
- The demon takes damage **only from lightning** in the final phase, so there's no confusion about what to do.
- Place a large mana pickup next to the lightning pickup, so players who emptied their mana on the obelisks (or the armor spell) aren't stuck.
- **Performance:** draw lightning as a sprite or simple stretched quad with an emissive material, not a real-time light (CLAUDE.md rules 4–5). A screen flash can sell the hit.
- It needs real stats (damage, mana cost) that work against normal enemies too, not just a "boss key".

## Matchups

| Enemy | Good choice | Bad choice | Notes |
|-------|-------------|------------|-------|
| Armored mercenary | Warhammer | Sword, bow | Canon: resists sword and bow |
| Werewolf | Staff of fireball | | Canon: weak to fire |
| Imp (flying) | Wand of magic missile | | Homing vs. fast flyers |
| Crystal obelisks (Level 8) | Warhammer, staff of fireball, francisca, wand of magic missile (one each) | Any other weapon | Canon: icon on top of each obelisk shows its weapon |
| Great demon (final phase) | Lightning | Everything else | Canon: must use lightning |
