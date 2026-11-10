extends GutTest
## Explosion behavior with real physics bodies: direct hit, splash falloff,
## walls blocking splash, and reduced caster damage.

const FIREBALL_SCENE: PackedScene = preload("res://spells/fireball/fireball.tscn")
const FIREBALL_DATA: SpellData = preload("res://spells/fireball/fireball.tres")
const BODY_SIZE: Vector3 = Vector3(0.8, 1.8, 0.8)
const MAX_HEALTH: float = 1000.0

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


## A static box with its origin at its feet, like the player and enemies.
func _make_target(at: Vector3) -> HealthComponent:
	var body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = BODY_SIZE
	shape.shape = box
	shape.position.y = BODY_SIZE.y * 0.5
	body.add_child(shape)
	var health: HealthComponent = HealthComponent.new()
	health.name = HealthComponent.NODE_NAME
	health.max_health = MAX_HEALTH
	body.add_child(health)
	_world.add_child(body)
	body.global_position = at
	return health


func _make_wall(at: Vector3, size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	_world.add_child(body)
	body.global_position = at


## Explodes a fireball moving along -Z that hit [param collider] at [param point].
func _explode(collider: Object, point: Vector3, caster: CollisionObject3D) -> void:
	# Let the physics server register the new bodies before querying.
	await wait_physics_frames(2)
	var fireball: FireballProjectile = FIREBALL_SCENE.instantiate() as FireballProjectile
	fireball.explosion_scene = null
	_world.add_child(fireball)
	fireball.launch(point, Vector3.FORWARD * 10.0, 0.0, FIREBALL_DATA.damage, FIREBALL_DATA.damage_type, caster)
	fireball.apply_weapon_data(FIREBALL_DATA)
	fireball.set_physics_process(false)
	fireball._on_hit(collider, point)


func _damage_taken(health: HealthComponent) -> float:
	return MAX_HEALTH - health.current_health


func test_direct_hit_takes_direct_damage_only() -> void:
	var target: HealthComponent = _make_target(Vector3(0, 0, -5))
	await _explode(target.get_parent(), Vector3(0, 0.9, -4.6), null)
	assert_almost_eq(_damage_taken(target), FIREBALL_DATA.damage, 0.001)


func test_nearby_target_takes_falloff_splash() -> void:
	var target: HealthComponent = _make_target(Vector3(1.0, 0, -5))
	await _explode(null, Vector3(0, 0.9, -5), null)
	var taken: float = _damage_taken(target)
	assert_gt(taken, 0.0, "in radius takes splash")
	assert_lt(taken, FIREBALL_DATA.splash_damage, "but less than the center value")


func test_target_outside_radius_is_unhurt() -> void:
	var target: HealthComponent = _make_target(Vector3(FIREBALL_DATA.splash_radius + 1.0, 0, -5))
	await _explode(null, Vector3(0, 0.9, -5), null)
	assert_eq(_damage_taken(target), 0.0)


func test_wall_blocks_splash() -> void:
	var target: HealthComponent = _make_target(Vector3(1.5, 0, -5))
	_make_wall(Vector3(0.75, 1.5, -5), Vector3(0.2, 3.0, 3.0))
	await _explode(null, Vector3(0, 0.9, -5), null)
	assert_eq(_damage_taken(target), 0.0)


func test_caster_takes_scaled_splash() -> void:
	var caster_health: HealthComponent = _make_target(Vector3(1.0, 0, -5))
	var other: HealthComponent = _make_target(Vector3(-1.0, 0, -5))
	var caster: CollisionObject3D = caster_health.get_parent() as CollisionObject3D
	await _explode(null, Vector3(0, 0.9, -5), caster)
	assert_gt(_damage_taken(other), 0.0)
	assert_almost_eq(_damage_taken(caster_health),
		_damage_taken(other) * FIREBALL_DATA.caster_splash_scale, 0.001,
		"same distance, caster takes the scaled amount")
