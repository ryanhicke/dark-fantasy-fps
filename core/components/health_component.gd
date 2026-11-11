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

const NODE_NAME: StringName = &"HealthComponent"

@export var max_health: float = 100.0
## Optional. Scales incoming damage by type. Null takes all damage as-is.
@export var resistances: DamageResistances

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
	# Ignoring hits on the dead prevents double kills (and double died signals)
	# when several attacks land in the same frame. Immune hits (0) are ignored
	# entirely, so they don't cause pain or wake anything.
	if amount <= 0.0 or is_dead():
		return
	var applied: float = minf(amount, current_health)
	current_health -= applied
	damaged.emit(applied, type, source)
	health_changed.emit(current_health, max_health)
	if is_dead():
		died.emit(source)


func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Sets health directly (e.g. restoring the player between levels). Not
## damage: it never emits damaged or died.
func set_health(amount: float) -> void:
	current_health = clampf(amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
