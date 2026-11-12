class_name ViewFeel
extends Node
## Cosmetic camera and weapon motion: Doom-style weapon bob while walking,
## weapon sway that lags mouse turns, a dip on hard landings, and screen
## shake from damage and nearby explosions.
##
## Only moves the weapon holder's position and the camera's h/v offsets,
## which nothing else touches, so it never fights head bob or weapon
## animations. Purely visual, so it runs in _process.

## Fall speed (m/s) that gives the full landing dip.
const HARD_LANDING_SPEED: float = 12.0
## Fall speeds below this don't dip at all (small steps, stairs).
const MIN_LANDING_SPEED: float = 4.0

@export var player: Player
@export var camera: Camera3D
@export var weapon_holder: Node3D

@export_group("Weapon Bob")
@export var weapon_bob_enabled: bool = true
## Meters of side-to-side swing at full speed.
@export var weapon_bob_side: float = 0.025
## Meters of dip at full speed.
@export var weapon_bob_down: float = 0.018

@export_group("Weapon Sway")
## Meters of lag per pixel of mouse movement.
@export var sway_per_pixel: float = 0.00012
@export var sway_max: float = 0.03
## How fast sway returns to center (1/s).
@export var sway_return_speed: float = 10.0

@export_group("Landing")
## Camera dip in meters on a hard landing.
@export var landing_dip: float = 0.12
@export var landing_recover_speed: float = 6.0

@export_group("Shake")
@export var shake_enabled: bool = true
## Shake strength (0..1) per point of damage taken.
@export var shake_per_damage: float = 0.03
## Camera offset in meters at strength 1.
@export var shake_max_offset: float = 0.06
## Strength lost per second.
@export var shake_decay: float = 2.5

var _sway: Vector2 = Vector2.ZERO
var _holder_rest: Vector3 = Vector3.ZERO
var _was_on_floor: bool = true
var _last_fall_speed: float = 0.0
var _landing_offset: float = 0.0
var _shake: float = 0.0


func _ready() -> void:
	if player == null or camera == null or weapon_holder == null:
		push_error("ViewFeel: player, camera, and weapon_holder must be assigned.")
		set_process(false)
		set_process_unhandled_input(false)
		return
	_holder_rest = weapon_holder.position
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.screen_shake_requested.connect(add_shake)


func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	# Opposite the turn, so the weapon trails behind the view.
	_sway -= motion.screen_relative * sway_per_pixel
	_sway = _sway.limit_length(sway_max)


func _process(delta: float) -> void:
	_update_landing(delta)
	_update_weapon(delta)
	_update_shake(delta)


## Adds [param strength] (0..1) of shake, capped at 1.
func add_shake(strength: float) -> void:
	if shake_enabled:
		_shake = minf(_shake + strength, 1.0)


func _update_landing(delta: float) -> void:
	var on_floor: bool = player.is_on_floor()
	if on_floor and not _was_on_floor and _last_fall_speed > MIN_LANDING_SPEED:
		var weight: float = clampf(
			inverse_lerp(MIN_LANDING_SPEED, HARD_LANDING_SPEED, _last_fall_speed), 0.0, 1.0)
		_landing_offset = -landing_dip * weight
	if not on_floor:
		_last_fall_speed = maxf(-player.velocity.y, 0.0)
	_was_on_floor = on_floor
	_landing_offset = move_toward(_landing_offset, 0.0, landing_recover_speed * landing_dip * delta)


func _update_weapon(delta: float) -> void:
	_sway = _sway.move_toward(Vector2.ZERO, sway_return_speed * sway_max * delta)
	var offset: Vector3 = Vector3(_sway.x, -_sway.y, 0.0)
	if weapon_bob_enabled:
		var phase: float = player.get_bob_phase()
		var weight: float = player.get_bob_weight()
		# Doom's weapon arc: side to side once per stride, lowest in the
		# middle, so the weapon traces a U.
		offset.x += cos(phase) * weapon_bob_side * weight
		offset.y -= absf(sin(phase)) * weapon_bob_down * weight
	offset.y += _landing_offset * 0.5
	weapon_holder.position = _holder_rest + offset


func _update_shake(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, shake_decay * delta)
	# Squared, so small shakes fade out softly instead of stopping dead.
	var amount: float = _shake * _shake * shake_max_offset
	camera.h_offset = randf_range(-amount, amount)
	camera.v_offset = randf_range(-amount, amount) + _landing_offset


func _on_player_damaged(amount: float) -> void:
	add_shake(amount * shake_per_damage)
