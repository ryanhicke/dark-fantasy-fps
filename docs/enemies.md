# Enemies (working doc)

Status: **draft**. Same rules as [story.md](story.md): "Canon" is decided by the designer, "Ideas" are proposals.

Enemy stats live in `EnemyData` resources (health, speed, damage, sight range, pain chance; see CLAUDE.md). All enemies are billboarded sprites and use the base `Enemy` state machine (`IDLE`, `CHASE`, `ATTACK`, `PAIN`, `DIE`). Numbers are not set yet; the descriptions below say how enemies compare to each other.

## Overview

| Enemy | First level | Also in | Role | Canon summary |
|-------|-------------|---------|------|---------------|
| Bandit | 1 | 2, (3 as disguise) | Basic melee | |
| Bandit archer | 1 | 2, (3 as disguise) | Basic ranged | |
| Armored mercenary | 2 | (3 as disguise) | Heavy melee | Armor protects against sword and bow; warhammer does extra damage |
| Werewolf (disguised) | 3 | | Two-phase | Looks like a bandit, archer, or armored mercenary; when killed, rises again as a werewolf |
| Werewolf | 3 | 4, 5, 6, 8 | Melee | Hits hard, goes down easily |
| Skeleton | 4 | | Ambush | Weak; rises from the ground when you walk past |
| Apprentice wizard | 5 | 6 | Ranged caster | Shoots fireballs |
| Necromancer | 6 | | Boss | Wizard fireball attack + summons melee demons |
| Melee demon | 6 | 7, 8 | Strong melee | First summoned by the necromancer |
| Imp | 7 | 8 | Flying ranged | Shoots magic missiles |
| Great demon | 7 (seen) | 8 | Final boss | Defeated through 4 crystal obelisks and lightning |

## Human enemies

### Bandit
**Canon**
- Melee. First seen in Level 1 (the robbers' cave), again in Level 2.

### Bandit archer
**Canon**
- Ranged. First seen in Level 1, again in Level 2.

### Armored mercenary
**Canon**
- Heavy melee, first seen in Level 2 (the mercenary outpost).
- Armor protects against the sword and the bow.
- The warhammer (found in Level 2) does extra damage against them.
- Slower than bandits, so the player can back off while learning that sword and bow don't work well.

**Ideas**
- The first one should appear **before** the warhammer pickup, so the player meets the problem first (see [weapons.md](weapons.md#warhammer)).
- Code note: the armor should use the damage-type system (`take_damage(amount, type, source)`), e.g. reduced physical damage from blades and arrows, normal or bonus damage from blunt weapons.

## Beasts

### Werewolf (disguised)
**Canon**
- Level 3. Looks like one of the three known enemies (bandit, archer, armored mercenary).
- When killed, it rises again as a werewolf.
- Code: on death, the enemy turns into its werewolf form (or takes one from a pool) instead of spawning a new node, to avoid a stutter.
- **How to spot them:** a disguised werewolf **growls** (instead of the normal human alert sound). Players can learn to tell them apart, so the second phase doesn't feel unfair.
- Story: they are the mercenaries missing from the outpost in Level 2.

**Ideas**
- Play the growl when it wakes up (sees the player), so the warning comes before the fight. Optionally a low growl now and then while idle, so careful players can hear them from around a corner.

### Werewolf
**Canon**
- Strong damage, but goes down easily.
- Guards the lair entrance in Level 4 (no disguise). More werewolves inside the lair in Levels 5 and 6.
- Level 8: the great demon starts summoning werewolves after the 2nd obelisk is destroyed.
- Fast, so they close distance quickly; low health keeps it fair.
- Level 4: the **false lever** at the lair gate drops **2 werewolves** on the player.
- **Weak to fire:** they take extra damage from fire, which makes the staff of fireball a good choice in Levels 5–6.

## Undead and magic

### Skeleton
**Canon**
- Level 4. Weak, but rises from the ground when the player walks past.
- Story: the skeletons are the necromancer's failed attempts to raise his wife: each one rose "hollow" (see story.md, The necromancer).

**Ideas**
- Code note: skeletons only need to rise once. Use a trigger area so the AI doesn't check distance every frame (fits the "stagger AI updates" rule).

### Apprentice wizard
**Canon**
- Ranged caster, first seen in Level 5. Also in Level 6.
- Shoots fireballs.
- Their notes tell part of the story: they are scared of their master ("The master no longer sleeps." "He says the girl is the key.").
- **Sequel secret:** one apprentice wizard was never found, because the necromancer's wife possessed that apprentice's body. The player never learns this in this game (see story.md, The necromancer's wife).

## Demons

### Melee demon
**Canon**
- Strong melee. First appears in Level 6, summoned by the necromancer.
- Common in Hell (Level 7). Constantly summoned by the great demon in Level 8.

### Imp
**Canon**
- Flying, ranged. First seen in Level 7. Constantly summoned by the great demon in Level 8.
- Shoots magic missiles.

**Ideas**
- Fast flyers are the problem the wand of magic missile (homing, found in Level 6) solves. The imps use the same spell, a nice echo.

## Bosses

### Necromancer (Level 6)
**Canon**
- Boss at the end of Level 6.
- Same attack as the apprentice wizards (fireballs), and he also summons melee demons.
- Motive: wants to raise his dead wife, a powerful evil sorceress who died of the plague, as herself. He hired the werewolf mercenaries. He kidnaps the mayor's daughter because he needs a pure soul to exchange for his wife's evil soul (see story.md).

**Ideas**
- Phase 1: fireballs only. Phase 2 (below half health): starts summoning melee demons.

### Great demon (Level 8)
**Canon**
- Seen at the end of Level 7, with the mayor's daughter in a cage above it. Fought in Level 8.
- Can't be hurt directly. You must destroy **4 crystal obelisks**, each weak to one weapon (warhammer, staff of fireball, francisca, wand of magic missile), shown by an icon on top of the obelisk.
- Constantly summons melee demons and imps. After the **2nd** obelisk, it also summons werewolves.
- Gets harder after each obelisk.
- Each destroyed obelisk makes it **roar**, and a **crack of light** opens in its body.
- After all 4 obelisks are destroyed, it can be hurt, and you must kill it with **lightning**.
- It's huge, but still a billboarded sprite (CLAUDE.md rule 2), built from a few sprite layers so the cracks of light can be drawn on top.

**Ideas**
- Summon rate goes up after each obelisk.
- Final phase: it stops summoning (or summons less) and attacks directly. It takes damage **only from lightning**.
- See story.md, Level 8, for the arena and obelisk details, and [weapons.md](weapons.md#lightning) for lightning.
- **Performance:** "constantly summons" needs a **cap on how many summoned enemies can be alive at once** (e.g. 8–12). That keeps the fight within the integrated-GPU budget and stops it from becoming impossible. Use object pooling for summoned enemies (CLAUDE.md rule 7).