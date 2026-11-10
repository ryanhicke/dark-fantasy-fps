class_name Enemy
extends CharacterBody3D
## Base enemy body: senses the player, moves, and turns EnemyBrain decisions
## into actions and placeholder visuals.
##
## Expects children: CollisionShape3D, Sprite (MeshInstance3D with a
## billboard material_override), HealthComponent, and SightCast (RayCast3D).
## The material must be local to scene so color changes stay per-enemy.

## Seconds between line-of-sight checks while idle. Each enemy starts at a
## random offset, so a room full of enemies doesn't raycast on the same frame.
const SIGHT_CHECK_INTERVAL: float = 0.2

@export var data: EnemyData
## Separate from project gravity, matching the player.
@export var gravity: float = 15.0
## Meters above the target's origin that sight rays aim at (chest height).
@export var target_aim_height: float = 1.2

@export_group("Placeholder Visuals")
@export var pain_color: Color = Color(1.0, 0.15, 0.1)
@export var windup_color: Color = Color(1.0, 0.9, 0.5)
@export var corpse_color: Color = Color(0.2, 0.15, 0.12)
@export var hit_flash_duration: float = 0.15
## Sprite height multiplier once dead, so the corpse reads as lying down.
@export var corpse_height_scale: float = 0.25
@export var corpse_collapse_time: float = 0.2

var _brain: EnemyBrain
var _target: Node3D
var _target_health: HealthComponent
var _sight_timer: float = 0.0
var _can_see_target: bool = false
var _base_color: Color
var _color_tween: Tween

@onready var _health: HealthComponent = $HealthComponent
@onready var _sprite: MeshInstance3D = $Sprite
@onready var _material: StandardMaterial3D = _sprite.get_active_material(0) as StandardMaterial3D
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _sight_cast: RayCast3D = $SightCast


func _ready() -> void:
	if data == null:
		push_error("%s: no EnemyData assigned." % name)
		set_physics_process(false)
		return
	_brain = EnemyBrain.new(data)
	_brain.state_changed.connect(_on_brain_state_changed)
	_brain.attack_struck.connect(_on_brain_attack_struck)
	_health.max_health = data.max_health
	_health.reset()
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)
	_sight_cast.enabled = false
	_sight_cast.add_exception(self)
	_base_color = _material.albedo_color
	_sight_timer = randf() * SIGHT_CHECK_INTERVAL
	# One group lookup at spawn, never per frame. Levels are reloaded on
	# respawn, so the target never changes during an enemy's life.
	_target = get_tree().get_first_node_in_group(Player.GROUP) as Node3D
	_target_health = HealthComponent.find_on(_target)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var distance: float = INF
	var target_alive: bool = false
	if _target != null:
		distance = global_position.distance_to(_target.global_position)
		target_alive = _target_health == null or not _target_health.is_dead()

	# Sight only matters for waking up, so awake enemies skip the raycast.
	if _brain.state == EnemyBrain.State.IDLE and _target != null:
		_update_sight(delta, distance)
	_brain.update(delta, distance, _can_see_target, target_alive)

	var horizontal: Vector3 = Vector3.ZERO
	if _brain.state == EnemyBrain.State.CHASE and _target != null:
		var to_target: Vector3 = _target.global_position - global_position
		to_target.y = 0.0
		if to_target != Vector3.ZERO:
			horizontal = to_target.normalized() * data.move_speed
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()


func _update_sight(delta: float, distance: float) -> void:
	_sight_timer -= delta
	if _sight_timer > 0.0:
		return
	_sight_timer = SIGHT_CHECK_INTERVAL
	_can_see_target = distance <= data.sight_range and _has_line_of_sight()


func _has_line_of_sight() -> bool:
	var aim_point: Vector3 = _target.global_position + Vector3.UP * target_aim_height
	_sight_cast.target_position = _sight_cast.to_local(aim_point)
	_sight_cast.force_raycast_update()
	return _sight_cast.get_collider() == _target


func _on_damaged(_amount: float, _type: Damage.Type, _source: Node) -> void:
	# A lethal hit is handled entirely by _on_died.
	if _health.is_dead():
		return
	_brain.take_hit(randf())
	_kill_color_tween()
	_material.albedo_color = pain_color
	_color_tween = create_tween()
	_color_tween.tween_property(_material, "albedo_color", _state_color(), hit_flash_duration)


func _on_died(_source: Node) -> void:
	_brain.die()
	set_physics_process(false)
	# Deferred: changing collision state inside a physics callback is not allowed.
	_collision.set_deferred("disabled", true)
	var collapse: Tween = create_tween()
	collapse.tween_property(_sprite, "scale:y", corpse_height_scale, corpse_collapse_time)
	EventBus.enemy_killed.emit(self)


func _on_brain_state_changed(_new_state: EnemyBrain.State, _old_state: EnemyBrain.State) -> void:
	_set_color(_state_color())


func _on_brain_attack_struck(hit: bool) -> void:
	_set_color(_state_color())
	if hit and _target_health != null:
		_target_health.take_damage(data.attack_damage, data.attack_damage_type, self)


func _state_color() -> Color:
	match _brain.state:
		EnemyBrain.State.PAIN:
			return pain_color
		EnemyBrain.State.DIE:
			return corpse_color
		EnemyBrain.State.ATTACK:
			return windup_color if _brain.is_winding_up() else _base_color
	return _base_color


func _set_color(color: Color) -> void:
	_kill_color_tween()
	_material.albedo_color = color


func _kill_color_tween() -> void:
	if _color_tween != null:
		_color_tween.kill()
		_color_tween = null
