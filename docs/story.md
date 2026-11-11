# Game Story (working doc)

Status: **draft**. Anything under "Canon" is decided by the designer. Anything under "Ideas" or "Open questions" is a proposal and not decided until it moves into Canon.

## Premise

**Canon**

- Setting: the Middle Ages, the town of **Schwarzewiese** in the Black Forest (Schwarzwald), near the **Feldberg**, the highest mountain in the Black Forest.
- The necromancer lives on the Feldberg.
- The player is a young man from a poor family. With no money for farmland, he joins the city guard.
- 8 levels, played in a straight line (no hubs, no going back).
- The story runs from local bandits, to mercenaries, to werewolves, to a necromancer, and then into Hell. Each step is bigger and stranger than the one before.

**Ideas**

- **Time period:** around **1350**, a few years after the Black Death. Half-empty villages, abandoned farms, and fear of the forest suit the tone. They also explain why a poor young man can join the guard so quickly: the guard is short of men.
- **Tone:** like Hexen and Quake. Very little dialogue. The story comes through notes, the intermission screen, and what you see in the level. Keep the text short enough to read in a few seconds.
- **How the story is told:** each level ends with something you find (a note, the treasure, a ritual circle). The intermission screen shows 2–4 lines of text about it next to kills, secrets, and time. The engine already supports this, so no cutscenes are needed.

## Open questions

| # | Question | Ideas |
|---|----------|-------|
| 1 | How does the daughter fit the necromancer's ritual? | See the Necromancer section. |
| 2 | Lightning in Level 8: how exactly is it found and used? | Draft in Level 8 Ideas. |
| 3 | Can lightning be used after the boss? | Only if there's a post-game or an expansion. Otherwise it's a one-fight weapon, which is fine. |

## Characters

**Canon: no one has a name.** The characters are only "you", "the mayor's daughter", "the captain of the guard", "the mayor", and "the necromancer". Story text should be written around this (e.g. *"The captain handed you..."*, never a name).

### The player (Canon)
- A young guardsman from a poor family. The captain notices his initiative and fighting skill.

### The captain of the guard (Canon: dies before Level 3)
- **Idea:** give him one line before Level 1, so his death in Level 3 matters. He could be the one who gives you the sword. Finding his body (or his sword) at the start of Level 3 makes a strong first image.

### The mayor and his daughter (Canon: daughter kidnapped in Level 3)
- **Idea:** the period title is *Schultheiß* or *Bürgermeister*. The mayor could be the one who hired the mercenaries in the first place, to "protect" the town (see Ideas: a twist).

### The necromancer (Canon: final human villain, summons the Hell portal)

**Canon**
- He wants to raise his dead wife, a powerful evil sorceress, **as herself**: her full mind and power, not a mindless zombie. His own necromancy can only make zombies and skeletons, which is why he needs something more.

**Ideas**
- **Why Hell:** because she was an evil sorceress, her soul went to Hell when she died. A body can be raised from a grave, but her soul has to be pulled back from Hell. That's why he needs a portal.
- **Why the daughter:** the great demon holds the wife's soul and demands a price: an innocent life given through the portal. The daughter is that price. This ties together the kidnapping, the portal, and the Level 8 boss.
- **Clues in the levels:** a sealed tomb or preserved body of the wife in the lair (Level 5 or 6), a portrait of her, his diary pages ("She would not come back hollow. I will not have her hollow."). Story told through the world, no names needed.
- **Optional dark echo:** the skeletons the player fights in Level 4 are his failed attempts. Each one rose "hollow".

## Enemy roster

| Enemy | First level | Role | Notes |
|-------|-------------|------|-------|
| Bandit (melee) | 1 | Basic fodder | |
| Bandit archer | 1 | Ranged fodder | |
| Armored mercenary | 2 | Heavy melee | Resists sword and bow; weak to warhammer |
| Werewolf (hidden) | 3 | Two-phase | Looks like bandit, archer, or mercenary; when killed, rises as a werewolf: hits hard, dies fast |
| Werewolf (true form) | 4 | Guard | Werewolves without a disguise at the lair entrance |
| Skeleton | 4 | Ambush fodder | Weak; rises from the ground when the player walks past |
| Apprentice wizard | 5 | Ranged caster | Shoots fireballs |
| Necromancer | 6 (boss) | Boss | Wizard fireball + summons melee demons |
| Melee demon | 6 | Strong melee | Summoned by the necromancer; common in Hell |
| Imp (flying) | 7 | Flying ranged | Shoots magic missiles |
| Great demon | 7 (seen), 8 (boss) | Final boss | Can't be hurt directly; dies when all 4 crystal obelisks are destroyed; constantly summons melee demons and imps, and werewolves after the 2nd obelisk |

**Ideas / design notes**
- **Telling hidden werewolves apart in Level 3:** give them one small sign (yellow eyes, an odd growl when they wake up, or a wolf pelt over their shoulders). Then players can learn to spot them, and the second phase doesn't feel unfair.
- **Werewolf damage types:** if armor and resistance hooks exist later, werewolves could take extra damage from fire. That makes them a nice target for the staff of fireball in Levels 5–6.
- **Skeletons:** they only need to rise once. Use a trigger area so the AI doesn't check distance every frame (fits the "stagger AI updates" rule).
- **Imps that shoot magic missiles** are a nice echo: by then the player owns the same weapon.

## Weapon and spell progression

| Level | Weapon / item found | Type | Notes |
|-------|---------------------|------|-------|
| Start | Sword | Melee | |
| 1 | Bow | Ranged | |
| 2 | Warhammer | Melee | Bonus damage against armored enemies |
| 3 | Francisca | Ranged (thrown) | Throwing axe; stronger than the bow, shorter range |
| 4 | Wand of healing | Spell (protection) | Heals 10 HP for 20 mana |
| 5 | Staff of fireball | Spell (attack) | |
| 6 | Wand of magic missile | Spell (attack) | Homing; weaker than the bow |
| 7 | Armor spell | Spell (protection) | Very expensive mana cost; makes you invulnerable for 5 seconds |
| 8 | Lightning | Spell (attack) | Only after the last obelisk falls; used to kill the great demon |

**Design notes and questions**
- **Mana is new in Level 4.** The player has never seen a mana bar before this point. Hide the mana bar until the first spell is found, and place a mana pickup right next to the wand so the player learns how it works.
- **Francisca vs. the bow:** the bow stays useful for long range; the francisca is for mid range when you need more damage.
- **Francisca ammo (Canon):** a stack of axes. Throwing one uses one; you can't pick it back up. Refill from francisca pickups.
- **Armor spell (idea):** it should cost most of a full mana bar (e.g. 75–100 of 100), so it's a "save my life" button, not something to use in every fight. Give it a clear screen effect (a gold or silver tint on the HUD) and a sound when it runs out, so the player knows exactly when they can be hurt again.
- **Lightning:** the only weapon that can finish the great demon. See Level 8.
- **Magic missile vs. bow:** it is weaker but homing. That makes it the right choice against fast flying imps in Level 7. Good: Level 6 gives you the tool and Level 7 gives you the problem it solves.

## Levels

### Level 1 — The Robbers' Cave (*Räuberhöhle*)

**Canon**
- Bandits hiding in the Black Forest have been harassing local farmers.
- The captain is impressed by the player's initiative and fighting skill and sends him to stop them.
- A local you question says they are hiding in a *Räuberhöhle* (robbers' cave).
- Setting: a cave. Enemies: bandits (melee) and bandit archers.
- Start with only the sword. Find the bow in this level.
- **Exit:** find a note that says the bandits are working with a local mercenary company. Head to their outpost.

**Ideas**
- Start on the forest path outside the cave (a little daylight before going underground), then go inside.
- Show signs of the farms they robbed: crates of grain, stolen livestock pens inside the cave.
- Key/door: the bandit leader's locked strongbox room. The note is inside, next to a small pile of coins that don't belong to farmers. A hint of the mercenaries' payment.
- **Intermission text (draft):** *"The bandits were not working alone. Their leader carried a mercenary's seal and a list of farms marked for burning."*

### Level 2 — The Mercenary Outpost

**Canon**
- You find the mercenaries at their outpost.
- Enemies: bandits and archers again, plus **armored heavy melee** mercenaries who resist swords and bows.
- Find the **warhammer** (extra damage against armor).
- **Exit:** find the stolen treasure.

**Ideas**
- A wooden palisade fort: watchtowers with archers, a muddy yard, a longhouse, a stable.
- Place the warhammer **after** the first armored mercenary so the player feels the problem before getting the answer.
- **Story beat (proposed):** the treasure isn't just the farmers' goods. It includes the town's tax chest, or a payment from someone outside. This raises the question "Who paid the mercenaries?"
- **Intermission text (draft):** *"You recovered the stolen goods. But the outpost was half-empty. Where had the rest of the mercenaries gone? Smoke rose over the trees, toward home."*

### Level 3 — The Wolves' Camp

**Canon**
- You return to town. It has been attacked and badly damaged.
- The captain of the guard is dead. The mayor's teenage daughter has been kidnapped.
- Survivors say the attackers "were beasts".
- You track them to a camp in the woods.
- Enemies: werewolves, which first appear as one of the three known enemies (bandit, archer, armored mercenary). When killed, they rise again as werewolves: strong damage, but easy to kill.
- Find the **francisca** (a throwing axe: stronger than the bow, shorter range).
- **Exit:** find evidence that they were hired by a necromancer.

**Ideas**
- **Strong opening:** start in the burning town. A short, safe section (or a few weak enemies) walking through the ruins before entering the forest. Pass the captain's body. This is the turning point of the story.
- **Twist (proposed):** the "mercenaries" who left the outpost in Level 2 **were** the werewolves. That's why the outpost was half-empty, and it connects Levels 1–3 into one plot.
- Moonlight and fog for the camp (cheap: flat light + a fog color, no volumetrics).
- **Evidence:** a bone token or black-wax seal and an order written in a hand that isn't the mercenary captain's.
- **Intermission text (draft):** *"Silver coins and a black-wax seal. The beasts were paid, and the one who paid them does not deal in coin alone. The girl was taken up the Feldberg."*

### Level 4 — The Necromancer's Gate

**Canon**
- The entrance to the necromancer's lair. Werewolves guard the entrance.
- New enemy: **skeletons**. They are weak, but they rise from the ground when you walk past.
- You win the level when you figure out how to get into the lair.
- Find the **wand of healing** (heals 10 HP for 20 mana).

**Ideas**
- **Setting:** high on the Feldberg, above the tree line: bare rock, wind, snow patches, and a ruined monastery or old graveyard. Skeletons rising from the graves makes sense here.
- **Entry puzzle (keep it simple, Doom-style):** the main gate is sealed. Find 2–3 items (for example, skulls on pillars, or levers in mausoleums) to open it. This works with the existing key/door system.
- The wand of healing comes from a dead priest or monk who tried to stop the necromancer before you. A small story told through the environment.
- **Intermission text (draft):** *"The seal breaks. Cold air rises from below, smelling of candle smoke and grave dirt."*

### Level 5 — The Lair, Upper Halls

**Canon**
- First level inside the necromancer's lair.
- New enemy: **apprentice wizards** who shoot fireballs. Also more werewolves.
- New weapon: **staff of fireball**.
- **Exit:** find the entrance to the basement.

**Ideas**
- Libraries, laboratories, a dining hall with a rotten feast. A place that used to be grand.
- Notes from apprentices show they are scared. ("The master no longer sleeps." "He says the girl is the key.")
- Staff of fireball taken from a dead or fleeing apprentice: "use their weapon against them".

### Level 6 — The Basement / Ritual Chamber

**Canon**
- The basement. More apprentice wizards and werewolves.
- At the end you are too late: the necromancer has used the mayor's daughter to open a portal to Hell.
- **Boss:** the necromancer. Same attack as the wizards, but he also summons a new enemy: **melee demons**.
- New weapon: **wand of magic missile** (homing, weaker than the bow).
- After defeating the necromancer, you enter the portal to Hell.

**Ideas**
- Find the magic missile wand **before** the boss, so the player has time to try it.
- **Boss phases (simple):** phase 1, fireballs only; phase 2 (below half health), starts summoning demons.
- The daughter is pulled through the portal as the fight begins. Seen, but not reachable.
- **Intermission text (draft):** *"The necromancer falls, but the portal stays open. Through it you see her, carried away by something enormous. You step through."*

### Level 7 — Hell: The Fortress

**Canon**
- Hell. You are in an Oblivion-style fortress.
- Enemies: melee demons and flying imps that shoot magic missiles.
- No new weapon, but you find the **armor spell**: very expensive to cast, makes you invulnerable for 5 seconds.
- **Exit:** you find the mayor's daughter in a cage, hanging above a huge demon.

**Ideas**
- Strong color change (red/orange palette, black stone) so it clearly feels like a different world. Cheap to do with textures and fog color.
- Find the armor spell early enough to learn it: right after it, put a fight that is easy to survive with 5 seconds of invulnerability (e.g. running through a corridor of fire or a crowd of imps).
- **Lots of ammo and mana** to prepare for the final fight.
- The last room is a view of the great demon and the cage: the player sees the boss before fighting it.

### Level 8 — The Great Demon

**Canon**
- Final boss: the **great demon**, the huge demon from the end of Level 7.
- The demon can't be hurt directly. To defeat it, you destroy **4 crystal obelisks**.
- The demon **constantly summons melee demons and imps**.
- **The fight gets harder after each obelisk.** After the **2nd** obelisk, the demon also starts summoning **werewolves**.
- **Feedback:** each destroyed obelisk makes the demon **roar**, and a **crack of light** opens in its body.
- **Each obelisk is weak to a different weapon or damage type**, so the player has to use the whole arsenal.
- **Supplies** (ammo, mana, health) are placed between obelisks.
- When all 4 obelisks are destroyed, the demon can be hurt. You get the **lightning** spell and must use it to kill the demon.

**Ideas**
- **Arena:** a large, mostly open area with the demon in the middle and one obelisk in each corner (or on raised platforms). The daughter's cage hangs above the demon.
- **Rising pressure besides werewolves:** summon rate goes up after each obelisk.
- **Obelisk weaknesses (draft):** one per type, and the player must already own the weapon:
  1. Physical/blunt: **warhammer** (cracking crystal)
  2. Fire: **staff of fireball**
  3. Thrown: **francisca**
  4. Magic: **wand of magic missile** (homing helps if this obelisk is high up or behind a gap)
  - Show each weakness visually, e.g. by crystal color or a symbol on the obelisk, and make the obelisk flash when hit by the wrong weapon. Otherwise players may think it can't be damaged.
  - Code note: this fits the planned damage-type system (`take_damage(amount, type, source)`). Each obelisk takes damage only, or mostly, from its type.
- **How you get lightning (draft):** when the 4th obelisk shatters, its crystal power gathers in one spot in the arena as a glowing pickup (the lightning spell). The cracks of light in the demon's body all glow. That tells the player "this is the moment" and "this is the weapon".
- **Final phase:** the demon stops summoning (or summons less) and attacks directly. A short, focused duel. The demon takes damage **only from lightning**, so there's no confusion about what to do.
- **Mana:** place a large mana pickup next to the lightning pickup. Players who just used all their mana on the obelisks (and the armor spell) shouldn't be stuck with a weapon they can't fire.
- **Performance note:** lightning should be a sprite or simple stretched quad with an emissive material, not a real-time light (CLAUDE.md rules 4–5). A screen flash can sell the hit.
- **Performance note:** "constantly summons" needs a **cap on how many summoned enemies can be alive at once** (e.g. 8–12). That keeps the fight within the integrated-GPU budget and stops it from becoming impossible. Use object pooling for the summoned enemies (CLAUDE.md rule 7).
- **After the kill:** the cage drops (or lowers safely), the daughter is freed, and a portal home opens. Walking into it ends the game.

## Ending

**Canon**
- You bring the mayor's daughter back to town.
- The mayor rewards you by making you the **new captain of the guard**.

**Ideas**
- **Full circle:** the game starts with a poor young man who only joined the guard because he had no money for land, and ends with him taking the place of the captain who first trusted him. If the captain gave you your sword in the intro, the mayor could hand it back to you at the end (or the captain's own sword).
- **Presentation:** a final text screen in the intermission style (cheap, matches the rest of the game), optionally over a still image of the rebuilt town.
- **Draft ending text:** *"The town still smelled of ash when you carried her through the gate. The mayor wept, then stood straight and gave you the captain's sword. The forest is quiet now. For now."*
- **Optional sequel hook:** one sinister line at the very end (e.g. one of the apprentice wizards was never found). Leave it out if you want a clean ending.

## Story beats checklist (what each level ending reveals)

1. The bandits work for mercenaries.
2. The mercenaries have the treasure, but where are the rest of them?
3. The beasts were hired by a necromancer. The daughter has been taken north.
4. Way into the lair found.
5. The daughter is "the key".
6. Too late: portal open. The necromancer is defeated.
7. The daughter is alive, in a cage above the great demon.
8. Destroy the 4 obelisks, take up lightning, kill the great demon, rescue the daughter.
9. Ending: home, and the player becomes captain of the guard.
