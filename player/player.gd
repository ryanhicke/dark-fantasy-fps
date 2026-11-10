class_name Player
extends CharacterBody3D
## First-person player: ground/air movement, jumping, mouse look, head bob.
##
## Body yaw handles left/right look; Head pitch handles up/down. Keeping them
## separate means movement direction never depends on vertical look.

const PITCH_LIMIT: float = 89.0 * PI / 180.0
## How fast head bob fades in/out when starting, stopping, or leaving the floor.
const HEAD_BOB_BLEND_SPEED: float = 6.0

@export_group("Movement")
## Top horizontal speed in m/s. Doom-style: fast, always running.
@export var move_speed: float = 8.0
## m/s² toward the target velocity while grounded with input held.
@export var ground_acceleration: float = 60.0
## m/s² toward zero while grounded with no input. High = snappy stops.
@export var ground_friction: float = 50.0
## m/s² of steering while airborne. Low, so jumps commit to a direction.
@export var air_acceleration: float = 15.0
@export var jump_velocity: float = 5.5
## Separate from the project gravity so jump arc can be tuned on its own.
@export var gravity: float = 15.0

@export_group("Look")
## Radians of rotation per pixel of mouse movement.
@export var mouse_sensitivity: float = 0.002

@export_group("Head Bob")
@export var head_bob_enabled: bool = true
## Peak vertical camera offset in meters at full speed.
@export var head_bob_amplitude: float = 0.04
## Meters travelled per full bob cycle. Tying bob to distance (not time)
## keeps it in step with movement at any speed.
@export var head_bob_stride: float = 2.5

var _bob_phase: float = 0.0
var _bob_weight: float = 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# screen_relative ignores window stretch scaling, so sensitivity
			# stays the same regardless of window size or render resolution.
			var motion: InputEventMouseMotion = event as InputEventMouseMotion
			rotate_y(-motion.screen_relative.x * mouse_sensitivity)
			_head.rotation.x = clampf(
				_head.rotation.x - motion.screen_relative.y * mouse_sensitivity,
				-PITCH_LIMIT, PITCH_LIMIT
			)
	elif event.is_action_pressed("ui_cancel"):
		# Stopgap until a pause menu owns mouse capture.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.is_pressed():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			# Consume the recapture click so it never fires a weapon later.
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var on_floor: bool = is_on_floor()

	if not on_floor:
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Basis is yaw-only, so this stays horizontal and keeps input magnitude.
	var wish_dir: Vector3 = transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var has_input: bool = input_dir != Vector2.ZERO

	if on_floor:
		if has_input:
			horizontal = horizontal.move_toward(wish_dir * move_speed, ground_acceleration * delta)
		else:
			horizontal = horizontal.move_toward(Vector3.ZERO, ground_friction * delta)
	elif has_input:
		# No air friction: releasing keys mid-jump keeps momentum.
		horizontal = horizontal.move_toward(wish_dir * move_speed, air_acceleration * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()


func _process(delta: float) -> void:
	var speed: float = Vector2(velocity.x, velocity.z).length()
	var target_weight: float = 0.0
	if head_bob_enabled and is_on_floor():
		target_weight = clampf(speed / move_speed, 0.0, 1.0)
	_bob_weight = move_toward(_bob_weight, target_weight, HEAD_BOB_BLEND_SPEED * delta)
	_bob_phase = fmod(_bob_phase + speed * delta * TAU / head_bob_stride, TAU)
	_camera.position.y = sin(_bob_phase) * head_bob_amplitude * _bob_weight
