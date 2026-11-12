class_name MeleeWeapon
extends Weapon
## Swings while the trigger is held. After the windup, sweeps a sphere
## forward from the camera and damages the nearest thing that can be hurt.
##
## Expects a child ShapeCast3D named "HitCast". It stays disabled and is only
## updated at the moment of a strike, so it costs nothing between swings.

@export_group("Swing Animation")
## View model rotation offset (degrees) at the end of the windup.
@export var windup_rotation_deg: Vector3 = Vector3(25.0, -15.0, 10.0)
## View model rotation offset (degrees) at the end of the strike.
@export var strike_rotation_deg: Vector3 = Vector3(-55.0, 35.0, -25.0)
## Seconds for the fast strike motion after the windup.
@export var strike_time: float = 0.07

## Negative means no swing is winding up.
var _windup_remaining: float = -1.0
var _rest_rotation: Vector3 = Vector3.ZERO
var _swing_tween: Tween

@onready var _hit_cast: ShapeCast3D = $HitCast


func _ready() -> void:
	super()
	if _view_model != null:
		_rest_rotation = _view_model.rotation
	# Top-level so the cast follows the camera, not the swinging view model.
	_hit_cast.top_level = true
	_hit_cast.enabled = false
	_hit_cast.target_position = Vector3.FORWARD * data.melee_range
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = data.melee_radius
	_hit_cast.shape = sphere


func setup(owner_body: CollisionObject3D, aim: Node3D, inventory: Inventory) -> void:
	super(owner_body, aim, inventory)
	if owner_body != null:
		_hit_cast.add_exception(owner_body)


func _tick(delta: float) -> void:
	if _windup_remaining >= 0.0:
		_windup_remaining -= delta
		if _windup_remaining < 0.0:
			_strike()
	elif _trigger_held and can_attack():
		_begin_swing()


func _on_interrupted() -> void:
	_windup_remaining = -1.0
	if _swing_tween != null:
		_swing_tween.kill()
	if _view_model != null:
		_view_model.rotation = _rest_rotation


func _begin_swing() -> void:
	_begin_cooldown()
	_windup_remaining = data.windup
	_play_swing_animation()


func _strike() -> void:
	_hit_cast.global_transform = _aim.global_transform
	_hit_cast.force_shapecast_update()
	var target: HealthComponent = _find_nearest_target()
	if target != null:
		target.take_damage(data.damage, data.damage_type, _owner_body)
	# A swing through empty air makes only the swing sound.
	if target != null or _hit_cast.get_collision_count() > 0:
		_play_strike_sound(target != null)


## The cast stops at the first thing it touches, so a wall in front of an
## enemy blocks the hit. Of everything touched there, take the closest
## living target.
func _find_nearest_target() -> HealthComponent:
	var nearest: HealthComponent = null
	var nearest_distance_sq: float = INF
	var origin: Vector3 = _hit_cast.global_position
	for i: int in _hit_cast.get_collision_count():
		var health: HealthComponent = HealthComponent.find_on(_hit_cast.get_collider(i) as Node)
		if health == null or health.is_dead():
			continue
		var distance_sq: float = origin.distance_squared_to(_hit_cast.get_collision_point(i))
		if distance_sq < nearest_distance_sq:
			nearest = health
			nearest_distance_sq = distance_sq
	return nearest


func _play_swing_animation() -> void:
	if _view_model == null:
		return
	if _swing_tween != null:
		_swing_tween.kill()
	var windup_rotation: Vector3 = _rest_rotation + _degrees_to_radians(windup_rotation_deg)
	var strike_rotation: Vector3 = _rest_rotation + _degrees_to_radians(strike_rotation_deg)
	var recover_time: float = maxf(data.cooldown - data.windup - strike_time, 0.0)
	_swing_tween = create_tween()
	_swing_tween.tween_property(_view_model, "rotation", windup_rotation, data.windup)
	_swing_tween.tween_property(_view_model, "rotation", strike_rotation, strike_time)
	_swing_tween.tween_property(_view_model, "rotation", _rest_rotation, recover_time)


static func _degrees_to_radians(degrees: Vector3) -> Vector3:
	return Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z))
