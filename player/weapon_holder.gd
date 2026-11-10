class_name WeaponHolder
extends Node3D
## Owns the player's weapon instances, routes attack input to the active
## weapon, and sequences switching (lower the current one, raise the next).
##
## Lives under the camera so weapons follow the view and head bob.

## Weapon scenes in slot order: index 0 is key 1, index 1 is key 2, and so on.
@export var weapon_scenes: Array[PackedScene] = []

var _weapons: Array[Weapon] = []
var _current_index: int = -1
## Slot waiting to be switched to once the current weapon is not busy.
var _pending_index: int = -1
var _switching: bool = false
var _trigger_held: bool = false

@onready var _aim: Node3D = get_parent() as Node3D


func _ready() -> void:
	var body: CollisionObject3D = owner as CollisionObject3D
	for scene: PackedScene in weapon_scenes:
		var weapon: Weapon = scene.instantiate() as Weapon
		add_child(weapon)
		weapon.setup(body, _aim)
		weapon.holster_immediately()
		_weapons.append(weapon)
	if not _weapons.is_empty():
		_pending_index = 0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("attack"):
		# This runs before the player's recapture-click handling, so a click
		# made to recapture the mouse is ignored here rather than attacking.
		_trigger_held = event.is_pressed() and _is_mouse_captured()
	elif event.is_action_pressed("weapon_1"):
		request_slot(0)
	elif event.is_action_pressed("weapon_2"):
		request_slot(1)
	elif event.is_action_pressed("weapon_next"):
		_cycle(1)
	elif event.is_action_pressed("weapon_prev"):
		_cycle(-1)


func _physics_process(_delta: float) -> void:
	if not _is_mouse_captured():
		_trigger_held = false
	if _switching:
		return
	if _pending_index >= 0 and not _is_current_busy():
		_switch_to(_pending_index)
		_pending_index = -1
		return
	if _current_index >= 0:
		_weapons[_current_index].set_trigger(_trigger_held)


func request_slot(index: int) -> void:
	if index < 0 or index >= _weapons.size():
		return
	# Re-selecting the active slot cancels a queued switch.
	_pending_index = -1 if index == _current_index else index


func _cycle(step: int) -> void:
	if _weapons.size() < 2:
		return
	var from_index: int = _pending_index if _pending_index >= 0 else _current_index
	request_slot(wrapi(from_index + step, 0, _weapons.size()))


func _switch_to(index: int) -> void:
	_switching = true
	if _current_index >= 0:
		await _weapons[_current_index].holster()
	_current_index = index
	await _weapons[index].draw()
	_switching = false


func _is_current_busy() -> bool:
	return _current_index >= 0 and _weapons[_current_index].is_busy()


func _is_mouse_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
