extends GutTest
## Skeletons start hidden in the ground and rise once (docs/enemies.md).
## The RiseTrigger's physics overlap is tested by hand in the editor; here
## we drive the Enemy API it calls.

const SKELETON_SCENE_PATH: String = "res://enemies/skeleton/skeleton.tscn"
const RISE_WAIT: float = 1.2

var _skeleton: Enemy
var _collision: CollisionShape3D
var _sprite: MeshInstance3D


func before_each() -> void:
	_skeleton = (load(SKELETON_SCENE_PATH) as PackedScene).instantiate() as Enemy
	add_child_autofree(_skeleton)
	_collision = _skeleton.get_node("CollisionShape3D") as CollisionShape3D
	_sprite = _skeleton.get_node("Sprite") as MeshInstance3D
	# make_dormant is deferred until after the Enemy's _ready.
	await wait_physics_frames(2)


func test_starts_dormant() -> void:
	assert_false(_skeleton.is_physics_processing(), "no AI while buried")
	assert_true(_collision.disabled, "can't be hit or bumped while buried")
	assert_false(_sprite.visible)


func test_rises_and_becomes_active() -> void:
	_skeleton.rise_from_ground()
	assert_true(_sprite.visible, "visible as soon as it starts climbing")
	assert_true(_collision.disabled, "still intangible mid-climb")
	await wait_seconds(RISE_WAIT)
	assert_true(_skeleton.is_physics_processing())
	assert_false(_collision.disabled)
	assert_almost_eq(_sprite.scale.y, 1.0, 0.001)


func test_rises_only_once() -> void:
	_skeleton.rise_from_ground()
	await wait_seconds(RISE_WAIT)
	var health: HealthComponent = HealthComponent.find_on(_skeleton)
	health.take_damage(1000.0, Damage.Type.SLASH, null)
	_skeleton.rise_from_ground()
	await wait_seconds(RISE_WAIT)
	assert_false(_skeleton.is_physics_processing(), "a dead skeleton stays down")


func test_one_sword_hit_kills() -> void:
	var data: EnemyData = _skeleton.data
	var sword: WeaponData = load("res://weapons/sword/sword.tres") as WeaponData
	var hit: float = sword.damage * data.resistances.multiplier_for(sword.damage_type)
	assert_gte(hit, data.max_health)


## The warhammer doesn't exist yet; any blunt hit at least as strong as the
## sword must one-shot, so the warhammer will too.
func test_weak_to_blunt() -> void:
	assert_gt(_skeleton.data.resistances.multiplier_for(Damage.Type.BLUNT), 1.0)


func test_arrows_are_resisted() -> void:
	var data: EnemyData = _skeleton.data
	var bow: WeaponData = load("res://weapons/bow/bow.tres") as WeaponData
	assert_lt(data.resistances.multiplier_for(Damage.Type.PIERCE), 1.0)
	var full_draw: float = bow.max_charge_damage * data.resistances.multiplier_for(bow.damage_type)
	assert_lt(full_draw, data.max_health, "even a full draw doesn't one-shot")
