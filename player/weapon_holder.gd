class_name WeaponHolder
extends Node3D
## Owns the player's weapon instances, routes attack input to the active
## weapon, and sequences switching (lower the current one, raise the next).
##
## Every weapon in [member weapon_scenes] is instantiated up front, but only
## owned ones can be selected. Each weapon's number key is its
## WeaponData.slot, so a key always means the same weapon.
##
## Lives under the camera so weapons follow the view and head bob.

## Number-key actions, indexed by slot - 1. Built once, not per event.
const SLOT_ACTIONS: Array[StringName] = [
	&"weapon_1", &"weapon_2", &"weapon_3", &"weapon_4", &"weapon_5",
	&"weapon_6", &"weapon_7", &"weapon_8", &"weapon_9",
]

## Every weapon the player can ever own, in any order.
@export var weapon_scenes: Array[PackedScene] = []
## WeaponData.ids owned on a fresh (pistol) start.
@export var starting_weapons: Array[StringName] = [&"sword"]
## Ammo source for weapons. Leave empty for unlimited ammo.
@export var inventory: Inventory

## All weapons, sorted by slot.
var _weapons: Array[Weapon] = []
var _owned: Array[StringName] = []
var _current_index: int = -1
## Weapon waiting to be switched to once the current weapon is not busy.
var _pending_index: int = -1
var _switching: bool = false
var _trigger_held: bool = false
var _was_mouse_captured: bool = false

@onready var _aim: Node3D = get_parent() as Node3D


func _ready() -> void:
	var body: CollisionObject3D = owner as CollisionObject3D
	for scene: PackedScene in weapon_scenes:
		var weapon: Weapon = scene.instantiate() as Weapon
		add_child(weapon)
		weapon.setup(body, _aim, inventory)
		weapon.holster_immediately()
		_weapons.append(weapon)
		if inventory == null and weapon.data != null and weapon.data.ammo_type != &"":
			push_warning("WeaponHolder: %s uses ammo but no inventory is assigned; ammo is unlimited."
				% weapon.data.display_name)
	_weapons.sort_custom(func(a: Weapon, b: Weapon) -> bool: return a.data.slot < b.data.slot)
	set_owned(starting_weapons)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("attack"):
		# This runs before the player's recapture-click handling, so a click
		# made to recapture the mouse is ignored here rather than attacking.
		_trigger_held = event.is_pressed() and _is_mouse_captured()
		return
	if event.is_action_pressed("weapon_next"):
		_cycle(1)
		return
	if event.is_action_pressed("weapon_prev"):
		_cycle(-1)
		return
	for i: int in SLOT_ACTIONS.size():
		if event.is_action_pressed(SLOT_ACTIONS[i]):
			request_slot(i + 1)
			return


func _physics_process(_delta: float) -> void:
	var captured: bool = _is_mouse_captured()
	if not captured:
		_trigger_held = false
		# Releasing the mouse mid-draw cancels the shot instead of firing it.
		if _was_mouse_captured and _current_index >= 0:
			_weapons[_current_index].interrupt()
	_was_mouse_captured = captured
	if _switching:
		return
	if _pending_index >= 0 and not _is_current_busy():
		_switch_to(_pending_index)
		_pending_index = -1
		return
	if _current_index >= 0:
		_weapons[_current_index].set_trigger(_trigger_held)


func owns(id: StringName) -> bool:
	return _owned.has(id)


## Copy of the owned ids, for the player state bundle.
func get_owned() -> Array[StringName]:
	return _owned.duplicate()


## Replaces what is owned (level start, restoring a bundle). Ids of weapons
## not in weapon_scenes are ignored. Raises the lowest owned slot if the
## current weapon is no longer owned.
func set_owned(ids: Array[StringName]) -> void:
	_owned.clear()
	for weapon: Weapon in _weapons:
		if ids.has(weapon.data.id):
			_owned.append(weapon.data.id)
	var current_owned: bool = _current_index >= 0 and owns(_weapons[_current_index].data.id)
	if not current_owned:
		_pending_index = _first_owned_index()


## Adds a weapon. Returns true if it was new, in which case it is also
## switched to, like picking up a weapon in Doom.
func give_weapon(id: StringName) -> bool:
	var index: int = _index_of(id)
	if index < 0 or owns(id):
		return false
	_owned.append(id)
	_pending_index = index
	return true


## Every weapon this holder knows about, for pickups and dev tools.
func get_all_weapon_data() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for weapon: Weapon in _weapons:
		result.append(weapon.data)
	return result


func request_slot(slot: int) -> void:
	var index: int = _index_of_slot(slot)
	if index < 0:
		return
	# Re-selecting the active weapon cancels a queued switch.
	_pending_index = -1 if index == _current_index else index


func _cycle(step: int) -> void:
	var from_index: int = _pending_index if _pending_index >= 0 else _current_index
	if from_index < 0:
		return
	# Walk the slot-sorted list, skipping weapons that aren't owned.
	var index: int = from_index
	for i: int in _weapons.size():
		index = wrapi(index + step, 0, _weapons.size())
		if owns(_weapons[index].data.id):
			_pending_index = -1 if index == _current_index else index
			return


func _index_of(id: StringName) -> int:
	for i: int in _weapons.size():
		if _weapons[i].data.id == id:
			return i
	return -1


## The owned weapon on [param slot], or -1.
func _index_of_slot(slot: int) -> int:
	for i: int in _weapons.size():
		if _weapons[i].data.slot == slot and owns(_weapons[i].data.id):
			return i
	return -1


func _first_owned_index() -> int:
	for i: int in _weapons.size():
		if owns(_weapons[i].data.id):
			return i
	return -1


func _switch_to(index: int) -> void:
	_switching = true
	if _current_index >= 0:
		await _weapons[_current_index].holster()
	_current_index = index
	EventBus.player_weapon_changed.emit(_weapons[index].data)
	await _weapons[index].draw()
	_switching = false


func _is_current_busy() -> bool:
	return _current_index >= 0 and _weapons[_current_index].is_busy()


func _is_mouse_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
