extends GutTest
## Melee demon and imp rules (docs/enemies.md).

const DEMON_PATH: String = "res://enemies/melee_demon/melee_demon.tres"
const IMP_PATH: String = "res://enemies/imp/imp.tres"
const IMP_SCENE_PATH: String = "res://enemies/imp/imp.tscn"
const BANDIT_PATH: String = "res://enemies/bandit/bandit.tres"
const PLAYER_SPEED: float = 8.0
const IMP_START_HEIGHT: float = 4.0
const FALL_WAIT: float = 0.8

var _demon: EnemyData
var _imp: EnemyData


func before_all() -> void:
	_demon = load(DEMON_PATH) as EnemyData
	_imp = load(IMP_PATH) as EnemyData


func test_demon_is_strong_melee() -> void:
	var bandit: EnemyData = load(BANDIT_PATH) as EnemyData
	assert_false(_demon.is_ranged())
	assert_gt(_demon.max_health, bandit.max_health * 2.0)
	assert_gt(_demon.attack_damage, bandit.attack_damage * 2.0)


func test_imp_flies_and_shoots_homing_magic() -> void:
	assert_true(_imp.flying)
	assert_true(_imp.is_ranged())
	assert_eq(_imp.attack_damage_type, Damage.Type.MAGIC)
	var spell: SpellData = _imp.projectile_data as SpellData
	assert_gt(spell.homing_turn_rate, 0.0)


## Strafing must still dodge: the missile's turning circle (speed / turn
## rate) has to be wider than a few meters.
func test_imp_missile_is_dodgeable() -> void:
	var spell: SpellData = _imp.projectile_data as SpellData
	assert_gt(_imp.projectile_speed / spell.homing_turn_rate, 5.0)
	assert_lt(_imp.move_speed, PLAYER_SPEED)


func test_dead_imp_falls_to_the_floor() -> void:
	var floor_body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(10.0, 1.0, 10.0)
	shape.shape = box
	shape.position = Vector3.DOWN * 0.5
	floor_body.add_child(shape)
	add_child_autofree(floor_body)
	var imp: Enemy = (load(IMP_SCENE_PATH) as PackedScene).instantiate() as Enemy
	add_child_autofree(imp)
	imp.global_position = Vector3.UP * IMP_START_HEIGHT
	await wait_physics_frames(2)
	assert_almost_eq(imp.global_position.y, IMP_START_HEIGHT, 0.01, "idle imp hovers, no gravity")
	HealthComponent.find_on(imp).take_damage(1000.0, Damage.Type.SLASH, null)
	await wait_seconds(FALL_WAIT)
	assert_almost_eq(imp.global_position.y, 0.0, 0.05)
