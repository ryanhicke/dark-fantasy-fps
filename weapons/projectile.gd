class_name Projectile
extends Node3D
## Base for physical projectiles (arrows now, fireballs later).
##
## Moves itself every physics tick and ray-casts along the segment it just
## travelled, so fast projectiles can't skip through thin walls between
## ticks. Uses a child RayCast3D named "PathCast" (disabled, updated
## manually) instead of direct space queries, because those allocate a
## result Dictionary every call.

## Seconds before a projectile that hit nothing removes itself.
@export var lifetime: float = 6.0

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 0.0
var damage: float = 0.0
var damage_type: Damage.Type = Damage.Type.PIERCE
var source: Node = null

var _age: float = 0.0

@onready var _path_cast: RayCast3D = $PathCast


## Call after adding the projectile to the scene tree.
func launch(
	start: Vector3,
	initial_velocity: Vector3,
	projectile_gravity: float,
	hit_damage: float,
	type: Damage.Type,
	attacker: CollisionObject3D
) -> void:
	global_position = start
	velocity = initial_velocity
	gravity = projectile_gravity
	damage = hit_damage
	damage_type = type
	source = attacker
	if attacker != null:
		_path_cast.add_exception(attacker)
	_face_velocity()


## Called by the firing weapon after launch() so subclasses can read extra
## fields from their data (e.g. splash from SpellData). Base needs nothing.
func apply_weapon_data(_weapon_data: WeaponData) -> void:
	pass


## One step of the flight model. Static so tests can run the exact same
## math the game uses.
static func integrate_velocity(current: Vector3, gravity_strength: float, delta: float) -> Vector3:
	return current + Vector3.DOWN * gravity_strength * delta


## Launch velocity that flies from [param from] toward [param to] at
## [param speed], aimed up just enough to cancel [param gravity_strength]
## over the flight. Ignores target movement (Doom-style: dodging works).
static func aim_velocity(from: Vector3, to: Vector3, speed: float, gravity_strength: float) -> Vector3:
	var offset: Vector3 = to - from
	var distance: float = offset.length()
	if distance <= 0.0 or speed <= 0.0:
		return Vector3.ZERO
	var velocity: Vector3 = offset / distance * speed
	# The drop over the flight time t is g*t²/2; an extra upward g*t/2 at
	# launch cancels it at the target. Exact enough at enemy ranges.
	velocity.y += gravity_strength * (distance / speed) * 0.5
	return velocity


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	velocity = integrate_velocity(velocity, gravity, delta)
	var next_position: Vector3 = global_position + velocity * delta
	_path_cast.target_position = _path_cast.to_local(next_position)
	_path_cast.force_raycast_update()
	if _path_cast.is_colliding():
		_on_hit(_path_cast.get_collider(), _path_cast.get_collision_point())
		return
	global_position = next_position
	_face_velocity()


## Override for different impact behavior (explosions, sticking, etc.).
func _on_hit(collider: Object, _point: Vector3) -> void:
	var health: HealthComponent = HealthComponent.find_on(collider as Node)
	if health != null:
		health.take_damage(damage, damage_type, source)
	queue_free()


func _face_velocity() -> void:
	var direction: Vector3 = velocity.normalized()
	# look_at fails when the direction is parallel to the up vector.
	if direction != Vector3.ZERO and absf(direction.dot(Vector3.UP)) < 0.999:
		look_at(global_position + direction, Vector3.UP)
