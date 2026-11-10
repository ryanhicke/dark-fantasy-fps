class_name Damage
extends RefCounted
## Shared damage vocabulary. Every hit carries a type so armor and
## resistances can be added later without changing the call sites.

enum Type {
	PHYSICAL,
	FIRE,
	LIGHTNING,
}
