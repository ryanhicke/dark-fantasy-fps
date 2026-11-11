extends GutTest
## Wand of magic missile: design rules and the lock-on (HomingLock).

const WAND: SpellData = preload("res://spells/magic_missile/magic_missile.tres")
const BOW: WeaponData = preload("res://weapons/bow/bow.tres")
const IMP: EnemyData = preload("res://enemies/imp/imp.tres")
const BANDIT_SCENE: PackedScene = preload("res://enemies/bandit/bandit.tscn")
const CONE: float = deg_to_rad(20.0)
const RANGE: float = 40.0
const SETTLE_FRAMES: int = 3

var _arena: Node3D
var _sight: RayCast3D


func before_each() -> void:
	_arena = Node3D.new()
	add_child_autofree(_arena)
	_sight = RayCast3D.new()
	_sight.enabled = false
	_sight.top_level = true
	_arena.add_child(_sight)


func _bandit_at(position: Vector3) -> Enemy:
	var bandit: Enemy = BANDIT_SCENE.instantiate() as Enemy
	_arena.add_child(bandit)
	bandit.global_position = position
	return bandit


func _wall_at(z: float) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(10.0, 5.0, 0.5)
	shape.shape = box
	wall.add_child(shape)
	_arena.add_child(wall)
	wall.global_position = Vector3(0.0, 1.0, z)


func _lock() -> Node3D:
	return HomingLock.find_target(get_tree(), Vector3.UP, Vector3.FORWARD, CONE, RANGE, _sight)


func test_wand_is_weaker_than_the_bow_and_homes() -> void:
	assert_lt(WAND.damage, BOW.damage)
	assert_eq(WAND.damage_type, Damage.Type.MAGIC)
	assert_eq(WAND.ammo_type, &"mana")
	assert_gt(WAND.homing_turn_rate, 0.0)
	assert_gt(WAND.homing_lock_angle_deg, 0.0)


func test_wand_missile_outruns_imps() -> void:
	assert_gt(WAND.projectile_speed, IMP.move_speed * 2.0)


func test_candidates_sorted_by_angle_within_cone_and_range() -> void:
	var points: Array[Vector3] = [
		Vector3(3.0, 0.0, -10.0),   # ~17 degrees off
		Vector3(0.5, 0.0, -10.0),   # nearly dead ahead
		Vector3(10.0, 0.0, -2.0),   # far outside the cone
		Vector3(0.0, 0.0, -50.0),   # dead ahead but out of range
	]
	var order: Array[int] = HomingLock.candidates_by_angle(Vector3.ZERO, Vector3.FORWARD, points, CONE, RANGE)
	assert_eq(order, [1, 0] as Array[int])


func test_locks_onto_a_visible_enemy() -> void:
	var bandit: Enemy = _bandit_at(Vector3(0.0, 0.0, -10.0))
	await wait_physics_frames(SETTLE_FRAMES)
	assert_eq(_lock(), bandit)


func test_does_not_lock_through_walls() -> void:
	_bandit_at(Vector3(0.0, 0.0, -10.0))
	_wall_at(-5.0)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_null(_lock())


func test_ignores_dead_enemies() -> void:
	var bandit: Enemy = _bandit_at(Vector3(0.0, 0.0, -10.0))
	await wait_physics_frames(SETTLE_FRAMES)
	HealthComponent.find_on(bandit).take_damage(1000.0, Damage.Type.SLASH, null)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_null(_lock())


func test_missile_lets_go_of_a_target_that_dies() -> void:
	var bandit: Enemy = _bandit_at(Vector3(5.0, 0.0, -10.0))
	await wait_physics_frames(SETTLE_FRAMES)
	var missile: HomingProjectile = WAND.projectile_scene.instantiate() as HomingProjectile
	_arena.add_child(missile)
	missile.launch(Vector3.UP, Vector3.FORWARD * WAND.projectile_speed, 0.0, WAND.damage, WAND.damage_type, null)
	missile.apply_weapon_data(WAND)
	missile.homing_target = bandit
	HealthComponent.find_on(bandit).take_damage(1000.0, Damage.Type.SLASH, null)
	await wait_physics_frames(SETTLE_FRAMES)
	assert_almost_eq(missile.velocity.normalized().angle_to(Vector3.FORWARD), 0.0, 0.0001, "flies straight on")
