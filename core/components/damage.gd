class_name Damage
extends RefCounted
## Shared damage vocabulary. Every hit carries a type so armor, resistances,
## and weaknesses (DamageResistances) can scale it.

## Values are explicit and must never be renumbered: .tres files store the
## number, not the name. SLASH keeps 0 because it replaced the old PHYSICAL.
enum Type {
	SLASH = 0,
	FIRE = 1,
	LIGHTNING = 2,
	PIERCE = 3,
	BLUNT = 4,
	## Raw arcane force, e.g. magic missile.
	MAGIC = 5,
	## Thrown weapons (the francisca). Separate from SLASH so the francisca's
	## obelisk can't be broken with the sword.
	THROWN = 6,
}
