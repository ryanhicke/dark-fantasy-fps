class_name Inventory
extends Node
## Player ammo counts, keyed by ammo type (e.g. &"arrows").
##
## Deliberately a small data holder so it can later be copied into and out
## of GameState's player bundle between levels.

signal ammo_changed(ammo_type: StringName, amount: int, maximum: int)

## Mana caps at 100 by design (docs/weapons.md); the armor spell costs 75.
@export var max_ammo: Dictionary[StringName, int] = {&"arrows": 100, &"axes": 30, &"mana": 100}
## Ammo given on a fresh (pistol) start.
@export var starting_ammo: Dictionary[StringName, int] = {&"arrows": 10, &"axes": 0, &"mana": 100}
## Points regained per second, up to the max. Set a type to 0 to disable
## regen (e.g. once mana pickups exist).
@export var regen_per_second: Dictionary[StringName, float] = {&"mana": 2.0}

var _ammo: Dictionary[StringName, int] = {}
## Fractional regen carried between ticks, since ammo counts are whole numbers.
var _regen_progress: Dictionary[StringName, float] = {}


func _ready() -> void:
	reset_to_starting()


func _physics_process(delta: float) -> void:
	regenerate(delta)


## Applies [param delta] seconds of regen. Public so tests can drive it.
func regenerate(delta: float) -> void:
	for ammo_type: StringName in regen_per_second:
		var rate: float = regen_per_second[ammo_type]
		# Reset when full so a just-spent point doesn't refill instantly.
		if rate <= 0.0 or get_ammo(ammo_type) >= get_max_ammo(ammo_type):
			_regen_progress[ammo_type] = 0.0
			continue
		var progress: float = _regen_progress.get(ammo_type, 0.0) + rate * delta
		var whole: int = floori(progress)
		if whole > 0:
			add_ammo(ammo_type, whole)
			progress -= whole
		_regen_progress[ammo_type] = progress


func reset_to_starting() -> void:
	_ammo.clear()
	for ammo_type: StringName in max_ammo:
		_set_ammo(ammo_type, starting_ammo.get(ammo_type, 0))


## Copy of every ammo count, for storing in the player state bundle.
func get_all_ammo() -> Dictionary[StringName, int]:
	return _ammo.duplicate()


## Restores counts saved by get_all_ammo(). Types missing from [param counts]
## drop to 0; unknown types are ignored.
func set_all_ammo(counts: Dictionary[StringName, int]) -> void:
	_regen_progress.clear()
	for ammo_type: StringName in max_ammo:
		_set_ammo(ammo_type, counts.get(ammo_type, 0))


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
