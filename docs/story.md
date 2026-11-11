# Game Story (working doc)

Status: **draft**. Anything under "Canon" is decided by the designer. Anything under "Ideas" or "Open questions" is a proposal and not decided until it moves into Canon.

## Premise

**Canon**

- Setting: the Middle Ages, around **1350**, a few years after the Black Death. The town of **Schwarzewiese** in the Black Forest (Schwarzwald), near the **Feldberg**, the highest mountain in the Black Forest.
- The necromancer lives on the Feldberg.
- The player is a young man from a poor family. With no money for farmland, he joins the city guard.
- 8 levels, played in a straight line (no hubs, no going back).
- The story runs from local bandits, to mercenaries, to werewolves, to a necromancer, and then into Hell. Each step is bigger and stranger than the one before.

**Ideas**

- **Why 1350 works:** half-empty villages, abandoned farms, and fear of the forest suit the tone. It also explains why a poor young man can join the guard so quickly: the guard is short of men.
- **Tone:** like Hexen and Quake. Very little dialogue. The story comes through notes, the intermission screen, and what you see in the level. Keep the text short enough to read in a few seconds.
- **How the story is told:** each level ends with something you find (a note, the treasure, a ritual circle). The intermission screen shows 2–4 lines of text about it next to kills, secrets, and time. The engine already supports this, so no cutscenes are needed.

## Open questions

None right now.

## Characters

**Canon: no one has a name.** The characters are only "you", "the mayor's daughter", "the captain of the guard", "the mayor", and "the necromancer". Story text should be written around this (e.g. *"The captain handed you..."*, never a name).

### The player (Canon)
- A young guardsman from a poor family. The captain notices his initiative and fighting skill.

### The captain of the guard

**Canon**
- He gives you your sword at the beginning of the game.
- He dies in the attack on the town before Level 3.

**Ideas**
- Give him one line when he hands you the sword, so his death in Level 3 matters.
- Finding his body (or his sword) at the start of Level 3 makes a strong first image.

### The mayor and his daughter (Canon: daughter kidnapped in Level 3)
- **Idea:** the period title is *Schultheiß* or *Bürgermeister*.

### The necromancer (Canon: final human villain, summons the Hell portal)

**Canon**
- His wife, a powerful evil sorceress, **died of the plague**.
- He wants to raise her **as herself**: her full mind and power, not a mindless zombie. His own necromancy can only make zombies and skeletons, which is why he needs something more.
- He **hired the mercenaries** (who are secretly werewolves) to raid the town and take the mayor's daughter.
- **Why he kidnaps the mayor's daughter:** he needs a **pure soul** to exchange for his wife's **evil soul**.
- **The trade:** the great demon holds the wife's soul and accepts the exchange: the daughter's pure soul for the wife's evil one. This is why the daughter ends up in a cage above the demon.
- **Clues in the levels (notes and objects):** the wife's tomb in the lair (Level 6), found **open and empty** (see The necromancer's wife), a portrait of her, and his diary pages ("She would not come back hollow. I will not have her hollow."). Story told through the world, no names needed.
- **The skeletons in Level 4 are his failed attempts** to raise her. Each one rose "hollow".

**Ideas**
- **Why Hell:** because she was an evil sorceress, her soul went to Hell when she died. A body can be raised from a grave, but her soul has to be pulled back from Hell. That's why he needs a portal.
- **Plague and the town:** if the plague also hit Schwarzewiese, the townspeople may remember the sorceress, or blame her. One diary line could hint at this.

### The necromancer's wife (secret: sequel setup)

**Canon**
- **The player never learns this in this game.** The wife's soul has **escaped Hell**, and she has returned as an **undead witch**.
- She is the **boss of the sequel**.
- Her tomb in the lair (Level 6) is found **open and empty**. It's the main hint, but the game never explains it.
- **She possessed one of the apprentice wizards.** That apprentice is never found. The undead witch is the wife's soul in that apprentice's body.
- **Hint: missing friend note (Level 5).** An apprentice's note: *"He went down to the tomb to pray for the master and hasn't come back. His bed hasn't been slept in for days."* It reads like a small mystery now and only makes sense after the sequel.
- **Hint: robe at the tomb (Level 6).** The missing apprentice's robe is left near the empty tomb.
- **Hint: the ending's last line** points to the empty tomb (see Ending).

**Ideas**
- From the player's view, the story is complete: the necromancer is dead, the demon is dead, the daughter is home. The witch's return is only revealed in the sequel.
- **More small hints for players who look closely** (none of them explain anything):
  - The tomb looks broken **from the inside** (lid pushed off, stone cracked outward), not opened by grave robbers.
  - In Hell (Level 7 or 8), an empty cell or broken chains where something important was held.
- Keep the hints vague enough that the ending still feels like a win, and clear enough that the sequel reveal feels planned, not made up later.

## Enemies

All enemy details (roles, behavior, design notes, boss mechanics) live in [enemies.md](enemies.md). The level sections below only list which enemies appear in each level.

## Weapons and spells

All weapon and spell details (stats, where each is found, design notes) live in [weapons.md](weapons.md). The level sections below only list which weapon or spell each level gives you.

## Levels

### Level 1 — The Robbers' Cave (*Räuberhöhle*)

**Canon**
- Bandits hiding in the Black Forest have been harassing local farmers.
- The captain is impressed by the player's initiative and fighting skill and sends him to stop them. He gives you your sword.
- A local you question says they are hiding in a *Räuberhöhle* (robbers' cave).
- Setting: a cave. Enemies: bandits (melee) and bandit archers.
- Start with only the sword. Find the bow in this level.
- **Exit:** find a note that says the bandits are working with a local mercenary company. Head to their outpost.
- The note is in the bandit leader's locked strongbox room (key/door), next to a small pile of coins that don't belong to farmers. A hint of the mercenaries' payment.

**Ideas**
- Start on the forest path outside the cave (a little daylight before going underground), then go inside.
- Show signs of the farms they robbed: crates of grain, stolen livestock pens inside the cave.
- **Intermission text (draft):** *"The bandits were not working alone. Their leader carried a mercenary's seal and a list of farms marked for burning."*

### Level 2 — The Mercenary Outpost

**Canon**
- You find the mercenaries at their outpost.
- Enemies: bandits and archers again, plus **armored heavy melee** mercenaries who resist swords and bows.
- Find the **warhammer** (extra damage against armor).
- The outpost is **half-empty**: many of the mercenaries are away (they are the werewolves who attack the town; see Level 3).
- **Exit:** find the stolen treasure. With it is the **necromancer's payment** to the mercenaries.

**Ideas**
- A wooden palisade fort: watchtowers with archers, a muddy yard, a longhouse, a stable.
- The player doesn't know yet who sent the payment. It's sealed with **black wax**, the same seal found in Level 3, so the reveal there connects back.
- **Intermission text (draft):** *"You recovered the stolen goods, and a purse of strange coin sealed in black wax. But the outpost was half-empty. Where had the rest of the mercenaries gone? Smoke rose over the trees, toward home."*

### Level 3 — The Wolves' Camp

**Canon**
- You return to town. It has been attacked and badly damaged.
- The captain of the guard is dead. The mayor's teenage daughter has been kidnapped.
- Survivors say the attackers "were beasts".
- **The attackers are the mercenaries missing from the outpost in Level 2. They are werewolves.**
- You track them to a camp in the woods.
- Enemies: werewolves, which first appear as one of the three known enemies (bandit, archer, armored mercenary). When killed, they rise again as werewolves: strong damage, but easy to kill.
- Find the **francisca**.
- **Exit:** find evidence that they were hired by a necromancer.
- **The evidence:** a bone token or black-wax seal and an order written in a hand that isn't the mercenary captain's.

**Ideas**
- **Strong opening:** start in the burning town. A short, safe section (or a few weak enemies) walking through the ruins before entering the forest. Pass the captain's body. This is the turning point of the story.
- Moonlight and fog for the camp (cheap: flat light + a fog color, no volumetrics).
- **Intermission text (draft):** *"Silver coins and a black-wax seal. The beasts were paid, and the one who paid them does not deal in coin alone. The girl was taken up the Feldberg."*

### Level 4 — The Necromancer's Gate

**Canon**
- The entrance to the necromancer's lair. Werewolves guard the entrance.
- New enemy: **skeletons**. They are weak, but they rise from the ground when you walk past. They are the necromancer's failed attempts to raise his wife.
- You win the level when you figure out how to get into the lair.
- **Entry puzzle:** pull **two levers** to open the gate. A **third, false lever** drops **2 werewolves** on you.
- Find the **wand of healing**.

**Ideas**
- **Setting:** high on the Feldberg, above the tree line: bare rock, wind, snow patches, and a ruined monastery or old graveyard. Skeletons rising from the graves makes sense here.
- **Levers:** give the player a fair chance to tell them apart: e.g. the real levers have the necromancer's black-wax/bone mark, the false one is plain. Players who don't look get punished, but not unfairly. It also works with the existing key/door system.
- **Intermission text (draft):** *"The seal breaks. Cold air rises from below, smelling of candle smoke and grave dirt."*

### Level 5 — The Lair, Upper Halls

**Canon**
- First level inside the necromancer's lair.
- New enemy: **apprentice wizards** who shoot fireballs. Also more werewolves.
- New weapon: **staff of fireball**.
- **Exit:** find the entrance to the basement.
- Notes from apprentices show they are scared. ("The master no longer sleeps." "He says the girl is the key.")
- One apprentice's note is about a missing friend who went down to the tomb (sequel hint; see The necromancer's wife).

**Ideas**
- Libraries, laboratories, a dining hall with a rotten feast. A place that used to be grand.

### Level 6 — The Basement / Ritual Chamber

**Canon**
- The basement. More apprentice wizards and werewolves.
- The wife's **empty tomb** is here, with the missing apprentice's **robe** next to it (sequel hints).
- At the end you are too late: the necromancer has used the mayor's daughter to open a portal to Hell.
- **Boss:** the necromancer. Same attack as the wizards, but he also summons a new enemy: **melee demons**.
- New weapon: **wand of magic missile**.
- After defeating the necromancer, you enter the portal to Hell.

**Ideas**
- The daughter is pulled through the portal as the fight begins. Seen, but not reachable.
- Put the tomb off the main path (a side crypt), so it feels like something the player found, not something the game pointed at.
- **Intermission text (draft):** *"The necromancer falls, but the portal stays open. Through it you see her, carried away by something enormous. You step through."*

### Level 7 — Hell: The Fortress

**Canon**
- Hell. You are in an Oblivion-style fortress.
- Enemies: melee demons and flying imps that shoot magic missiles.
- No new weapon, but you find the **armor spell**.
- **Exit:** you find the mayor's daughter in a cage, hanging above a huge demon.

**Ideas**
- Strong color change (red/orange palette, black stone) so it clearly feels like a different world. Cheap to do with textures and fog color.
- **Lots of ammo and mana** to prepare for the final fight.
- The last room is a view of the great demon and the cage: the player sees the boss before fighting it.

### Level 8 — The Great Demon

**Canon**
- Final boss: the **great demon**, the huge demon from the end of Level 7.
- The demon can't be hurt directly. To defeat it, you destroy **4 crystal obelisks**.
- The demon **constantly summons melee demons and imps**.
- **The fight gets harder after each obelisk.** After the **2nd** obelisk, the demon also starts summoning **werewolves**.
- **Feedback:** each destroyed obelisk makes the demon **roar**, and a **crack of light** opens in its body.
- **Each obelisk is weak to one weapon:**
  1. **Warhammer**
  2. **Staff of fireball**
  3. **Francisca**
  4. **Wand of magic missile**
- **The weakness is obvious:** an **icon of the right weapon on top of each obelisk**.
- **Supplies** (ammo, mana, health) are placed between obelisks.
- When all 4 obelisks are destroyed, the demon can be hurt. You get the **lightning** spell and must use it to kill the demon.

**Ideas**
- **Arena:** a large, mostly open area with the demon in the middle and one obelisk in each corner (or on raised platforms). The daughter's cage hangs above the demon.
- Put the magic missile obelisk high up or behind a gap, where homing helps.
- Make an obelisk flash (no damage) when hit by the wrong weapon, so players know it's the weapon, not a bug.
- Code note: this fits the planned damage-type system (`take_damage(amount, type, source)`). Each obelisk takes damage only from its weapon's type.
- Boss behavior (summoning, final phase, summon cap): see [enemies.md](enemies.md#great-demon-level-8). Lightning: see [weapons.md](weapons.md#lightning).
- **After the kill:** the cage drops (or lowers safely), the daughter is freed, and a portal home opens. Walking into it ends the game.

## Ending

**Canon**
- You bring the mayor's daughter back to town.
- The mayor rewards you by making you the **new captain of the guard**.
- **The last line of the ending points to the empty tomb** (sequel hook for the witch, without explaining her).

**Ideas**
- **Full circle:** the game starts with the captain giving a poor young guardsman his sword, and ends with that guardsman taking the captain's place. The mayor could give you the captain's own sword.
- **Presentation:** a final text screen in the intermission style (cheap, matches the rest of the game), optionally over a still image of the rebuilt town.
- **Draft ending text:** *"The town still smelled of ash when you carried her through the gate. The mayor wept, then stood straight and gave you the captain's sword. The forest is quiet now. For now."*
- **Draft last line:** *"Far up the Feldberg, in an empty tomb, the candles were burning again."*

## Story beats checklist (what each level ending reveals)

1. The bandits work for mercenaries.
2. The mercenaries have the treasure and a mysterious payment, but where are the rest of them?
3. The missing mercenaries were werewolves, hired by a necromancer. The daughter has been taken up the Feldberg.
4. Way into the lair found.
5. The daughter is "the key".
6. Too late: portal open. The necromancer is defeated.
7. The daughter is alive, in a cage above the great demon.
8. Destroy the 4 obelisks, take up lightning, kill the great demon, rescue the daughter.
9. Ending: home, and the player becomes captain of the guard. Last line: the empty tomb.
