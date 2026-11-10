class_name Weapon
extends Node3D
## Base for all player weapons.
##
## Owns trigger state, cooldown, and the raise/lower animation used when
## switching. Subclasses decide what an attack does by overriding the
## virtual hooks (_tick, _on_trigger_pressed, _on_trigger_released,
## _on_interrupted).
##
## Expects a child Node3D named "ViewModel" holding the visible mesh, so
## animations move the model without moving the weapon's own origin.

signal attacked

## Leftover cooldown below this counts as finished. Subtracting frame deltas
## leaves float residue (0.5 - 30 * 1/60 is not exactly 0), which would
## otherwise randomly add an extra frame between attacks.
const COOLDOWN_EPSILON: float = 0.0001

@export var data: WeaponData

@export_group("Switching")
## Seconds for the lower or raise half of a weapon switch.
@export var switch_time: float = 0.15
## Meters the view model drops below its rest position when holstered.
@export var holster_drop: float = 0.6

var _owner_body: CollisionObject3D
var _aim: Node3D
var _inventory: Inventory
var _trigger_held: bool = false
var _cooldown_remaining: float = 0.0
var _is_drawn: bool = false
var _rest_position: Vector3 = Vector3.ZERO
var _switch_tween: Tween

@onready var _view_model: Node3D = get_node_or_null("ViewModel") as Node3D


func _ready() -> void:
	if _view_model != null:
		_rest_position = _view_model.position


## Called once by the WeaponHolder. [param owner_body] is the damage source
## and is excluded from hit checks; [param aim] is where attacks originate;
## [param inventory] supplies ammo (null means unlimited).
func setup(owner_body: CollisionObject3D, aim: Node3D, inventory: Inventory) -> void:
	_owner_body = owner_body
	_aim = aim
	_inventory = inventory


func set_trigger(held: bool) -> void:
	if held == _trigger_held:
		return
	_trigger_held = held
	if held:
		_on_trigger_pressed()
	else:
		_on_trigger_released()


func can_attack() -> bool:
	return _is_drawn and data != null and _cooldown_remaining <= 0.0


## True while an attack is still playing out. Switching waits for this, like
## Doom, so an attack can't be cancelled halfway by changing weapons.
func is_busy() -> bool:
	return _cooldown_remaining > 0.0


func has_ammo() -> bool:
	if data == null or data.ammo_type == &"" or _inventory == null:
		return true
	return _inventory.has_ammo(data.ammo_type, data.ammo_cost)


## Spends ammo for one attack. Returns false (spending nothing) if short.
func _consume_ammo() -> bool:
	if data.ammo_type == &"" or _inventory == null:
		return true
	return _inventory.consume_ammo(data.ammo_type, data.ammo_cost)


## Cancels anything in progress without attacking, e.g. when the mouse is
## released mid-draw. Cleared directly, not via set_trigger(), so weapons
## that act on release (like a drawn bow) don't fire.
func interrupt() -> void:
	_trigger_held = false
	_on_interrupted()


func holster_immediately() -> void:
	_is_drawn = false
	interrupt()
	visible = false
	set_physics_process(false)
	if _view_model != null:
		_view_model.position = _holstered_position()


## Raise animation. Await it to know when the weapon is usable.
func draw() -> void:
	visible = true
	if _view_model != null:
		_view_model.position = _holstered_position()
		await _tween_view_model(_rest_position).finished
	_is_drawn = true
	set_physics_process(true)


## Lower animation. Cancels anything in progress without attacking.
func holster() -> void:
	_is_drawn = false
	interrupt()
	if _view_model != null:
		await _tween_view_model(_holstered_position()).finished
	visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
		if _cooldown_remaining < COOLDOWN_EPSILON:
			_cooldown_remaining = 0.0
	_tick(delta)


## Starts the cooldown and announces the attack. Subclasses call this at the
## moment an attack begins.
func _begin_cooldown() -> void:
	_cooldown_remaining = data.cooldown
	attacked.emit()


func _holstered_position() -> Vector3:
	return _rest_position + Vector3.DOWN * holster_drop


func _tween_view_model(target: Vector3) -> Tween:
	if _switch_tween != null:
		_switch_tween.kill()
	_switch_tween = create_tween()
	_switch_tween.tween_property(_view_model, "position", target, switch_time)
	return _switch_tween


# --- Virtual hooks -----------------------------------------------------------

func _tick(_delta: float) -> void:
	pass


func _on_trigger_pressed() -> void:
	pass


func _on_trigger_released() -> void:
	pass


func _on_interrupted() -> void:
	pass
