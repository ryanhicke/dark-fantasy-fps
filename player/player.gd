class_name Player
extends CharacterBody3D
## First-person player: ground/air movement, jumping, mouse look, head bob.
##
## Body yaw handles left/right look; Head pitch handles up/down. Keeping them
## separate means movement direction never depends on vertical look.

## Enemies find the player through this group once, when they spawn.
const GROUP: StringName = &"player"
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

@export_group("Death")
## Head height above the feet once dead, Doom-style view from the floor.
@export var death_head_height: float = 0.3
@export var death_head_drop_time: float = 0.5

@export_group("Use")
## Reach of the use key in meters from the eyes. Doom's was 64 units (2 m).
@export var use_range: float = 2.0

var _bob_phase: float = 0.0
var _bob_weight: float = 0.0
var _is_dead: bool = false

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var _health: HealthComponent = $HealthComponent
@onready var _use_cast: RayCast3D = $Head/Camera3D/UseCast


func _enter_tree() -> void:
	# In _enter_tree, not _ready: enemies look the player up in their own
	# _ready, which can run before the player's.
	add_to_group(GROUP)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_health.damaged.connect(_on_damaged)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	EventBus.player_health_changed.emit(_health.current_health, _health.max_health)
	# Updated only when use is pressed, so it costs nothing per frame.
	_use_cast.enabled = false
	_use_cast.target_position = Vector3.FORWARD * use_range
	_use_cast.add_exception(self)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not _is_dead:
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
	elif event.is_action_pressed("use") and not _is_dead:
		_try_use()
	elif event is InputEventMouseButton and event.is_pressed():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			# Consume the recapture click so it never fires a weapon later.
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var on_floor: bool = is_on_floor()

	if not on_floor:
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and not _is_dead:
		velocity.y = jump_velocity

	# Dead bodies keep gravity and friction so they settle instead of freezing.
	var input_dir: Vector2 = Vector2.ZERO
	if not _is_dead:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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


func _on_damaged(amount: float, _type: Damage.Type, _source: Node) -> void:
	EventBus.player_damaged.emit(amount)


func _on_health_changed(current: float, maximum: float) -> void:
	EventBus.player_health_changed.emit(current, maximum)


func _on_died(_source: Node) -> void:
	_is_dead = true
	# Disabling the holder stops weapon input and any attack in progress.
	_weapon_holder.process_mode = Node.PROCESS_MODE_DISABLED
	_weapon_holder.visible = false
	var drop: Tween = create_tween()
	drop.tween_property(_head, "position:y", death_head_height, death_head_drop_time)
	EventBus.player_died.emit()


## Doom-style use: whatever is in reach under the crosshair and has a
## use(user) method (doors now, switches later) gets activated.
func _try_use() -> void:
	_use_cast.force_raycast_update()
	var target: Node = _use_cast.get_collider() as Node
	if target != null and target.has_method(&"use"):
		target.call(&"use", self)
