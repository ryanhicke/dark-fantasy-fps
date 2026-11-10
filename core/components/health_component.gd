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


func take_damage(amount: float, type: Damage.Type, source: Node) -> void:
	# Ignoring hits on the dead prevents double kills (and double died signals)
	# when several attacks land in the same frame.
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
