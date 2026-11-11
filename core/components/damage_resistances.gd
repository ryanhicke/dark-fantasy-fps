class_name DamageResistances
extends Resource
## Per-damage-type multipliers: 1 is normal, below 1 resists, above 1 is a
## weakness, 0 is immune. Shared by every HealthComponent that uses it, so
## treat it as read-only at runtime.

@export var slash: float = 1.0
@export var pierce: float = 1.0
@export var blunt: float = 1.0
@export var fire: float = 1.0
@export var lightning: float = 1.0
@export var magic: float = 1.0
@export var thrown: float = 1.0


func multiplier_for(type: Damage.Type) -> float:
	match type:
		Damage.Type.SLASH:
			return slash
		Damage.Type.PIERCE:
			return pierce
		Damage.Type.BLUNT:
			return blunt
		Damage.Type.FIRE:
			return fire
		Damage.Type.LIGHTNING:
			return lightning
		Damage.Type.MAGIC:
			return magic
		Damage.Type.THROWN:
			return thrown
	push_error("DamageResistances: unhandled damage type %d" % type)
	return 1.0
