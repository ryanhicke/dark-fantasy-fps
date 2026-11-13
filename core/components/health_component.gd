class_name HealthComponent
extends Node
## The single entry point for all damage.
##
## Add as a child named "HealthComponent" to anything that can be hurt.
## Attackers look it up by that name on the collider they hit, so the lookup
## happens only on a hit, never per frame.

signal health_changed(current: float, maximum: float)
signal damaged(amount: float, type: Damage.Type, source: Node)
signal died(source: Node)
## A hit that resistances reduced to nothing (an immune damage type), on a
## living, non-invulnerable target. Lets e.g. an obelisk clink at the
## wrong weapon without the hit counting as damage.
signal immune_hit(type: Damage.Type, source: Node)

const NODE_NAME: StringName = &"HealthComponent"

@export var max_health: float = 100.0
## Optional. Scales incoming damage by type. Null takes all damage as-is.
@export var resistances: DamageResistances

## Scales every hit after resistances. The player's is set from the run's
## difficulty; everything else leaves it at 1.
var damage_taken_multiplier: float = 1.0
## While true, all damage is ignored (the armor spell; see Invulnerability).
var invulnerable: bool = false
## The player's cheat (see GodMode). Kept apart from [member invulnerable]
## so the armor spell wearing off can't switch the cheat off, or the cheat
## cut the spell short.
var cheat_invulnerable: bool = false

var current_health: float = 0.0


func _ready() -> void:
	current_health = max_health


## Returns the HealthComponent on [param target], or null if it can't be hurt.
static func find_on(target: Node) -> HealthComponent:
	if target == null:
		return null
	return target.get_node_or_null(NodePath(NODE_NAME)) as HealthComponent


func is_dead() -> bool:
	return current_health <= 0.0


## [param amount] is the raw hit; resistances are applied here, so every
## damage source respects them. The damaged signal reports the scaled amount.
func take_damage(amount: float, type: Damage.Type, source: Node) -> void:
	if resistances != null:
		amount *= resistances.multiplier_for(type)
	amount *= damage_taken_multiplier
	# Ignoring hits on the dead prevents double kills (and double died signals)
	# when several attacks land in the same frame. Immune hits (0) are ignored
	# entirely, so they don't cause pain or wake anything.
	var shielded: bool = invulnerable or cheat_invulnerable
	if amount <= 0.0 or is_dead() or shielded:
		if amount <= 0.0 and not is_dead() and not shielded:
			immune_hit.emit(type, source)
		return
	var applied: float = minf(amount, current_health)
	current_health -= applied
	damaged.emit(applied, type, source)
	health_changed.emit(current_health, max_health)
	if is_dead():
		died.emit(source)


## Restores up to [param amount], capped at max. Returns how much was
## actually restored. The dead can't be healed.
func heal(amount: float) -> float:
	if amount <= 0.0 or is_dead():
		return 0.0
	var restored: float = minf(amount, max_health - current_health)
	if restored > 0.0:
		current_health += restored
		health_changed.emit(current_health, max_health)
	return restored


func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Sets health directly (e.g. restoring the player between levels). Not
## damage: it never emits damaged or died.
func set_health(amount: float) -> void:
	current_health = clampf(amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
