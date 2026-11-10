class_name Inventory
extends Node
## Player ammo counts, keyed by ammo type (e.g. &"arrows").
##
## Deliberately a small data holder so it can later be copied into and out
## of GameState's player bundle between levels.

signal ammo_changed(ammo_type: StringName, amount: int, maximum: int)

@export var max_ammo: Dictionary[StringName, int] = {&"arrows": 100}
## Ammo given on a fresh (pistol) start.
@export var starting_ammo: Dictionary[StringName, int] = {&"arrows": 10}

var _ammo: Dictionary[StringName, int] = {}


func _ready() -> void:
	reset_to_starting()


func reset_to_starting() -> void:
	_ammo.clear()
	for ammo_type: StringName in max_ammo:
		_set_ammo(ammo_type, starting_ammo.get(ammo_type, 0))


func get_ammo(ammo_type: StringName) -> int:
	return _ammo.get(ammo_type, 0)


func get_max_ammo(ammo_type: StringName) -> int:
	return max_ammo.get(ammo_type, 0)


func has_ammo(ammo_type: StringName, amount: int) -> bool:
	return get_ammo(ammo_type) >= amount


## Spends [param amount] if there is enough. Returns false and spends
## nothing otherwise, so a shot never goes off half-paid.
func consume_ammo(ammo_type: StringName, amount: int) -> bool:
	if amount < 0 or not has_ammo(ammo_type, amount):
		return false
	_set_ammo(ammo_type, get_ammo(ammo_type) - amount)
	return true


## Adds up to the maximum. Returns how much was actually added, so a pickup
## can tell whether it was used.
func add_ammo(ammo_type: StringName, amount: int) -> int:
	if amount <= 0 or not max_ammo.has(ammo_type):
		return 0
	var added: int = mini(amount, get_max_ammo(ammo_type) - get_ammo(ammo_type))
	if added > 0:
		_set_ammo(ammo_type, get_ammo(ammo_type) + added)
	return added


func _set_ammo(ammo_type: StringName, amount: int) -> void:
	var clamped: int = clampi(amount, 0, get_max_ammo(ammo_type))
	_ammo[ammo_type] = clamped
	ammo_changed.emit(ammo_type, clamped, get_max_ammo(ammo_type))
	EventBus.player_ammo_changed.emit(ammo_type, clamped, get_max_ammo(ammo_type))
