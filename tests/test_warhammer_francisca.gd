extends GutTest
## Design rules for the warhammer and francisca (docs/weapons.md).

const SWORD: WeaponData = preload("res://weapons/sword/sword.tres")
const WARHAMMER: WeaponData = preload("res://weapons/warhammer/warhammer.tres")
const BOW: WeaponData = preload("res://weapons/bow/bow.tres")
const FRANCISCA: WeaponData = preload("res://weapons/francisca/francisca.tres")
const BANDIT: EnemyData = preload("res://enemies/bandit/bandit.tres")
const MERCENARY: EnemyData = preload("res://enemies/armored_mercenary/armored_mercenary.tres")
const SKELETON: EnemyData = preload("res://enemies/skeleton/skeleton.tres")
const EYE_HEIGHT: float = 1.6
const PHYSICS_DELTA: float = 1.0 / 60.0


func _hit(weapon: WeaponData, enemy: EnemyData) -> float:
	var multiplier: float = 1.0
	if enemy.resistances != null:
		multiplier = enemy.resistances.multiplier_for(weapon.damage_type)
	return weapon.damage * multiplier


## Horizontal distance of a level throw from eye height to the floor.
func _level_range(speed: float, gravity_strength: float) -> float:
	var position: Vector3 = Vector3(0.0, EYE_HEIGHT, 0.0)
	var velocity: Vector3 = Vector3.FORWARD * speed
	while position.y > 0.0:
		velocity = Projectile.integrate_velocity(velocity, gravity_strength, PHYSICS_DELTA)
		position += velocity * PHYSICS_DELTA
	return absf(position.z)


func test_warhammer_is_blunt_and_slower_than_the_sword() -> void:
	assert_eq(WARHAMMER.damage_type, Damage.Type.BLUNT)
	assert_gt(WARHAMMER.cooldown, SWORD.cooldown)


func test_warhammer_matches_the_sword_against_unarmored() -> void:
	assert_eq(_hit(WARHAMMER, BANDIT), _hit(SWORD, BANDIT))


func test_warhammer_beats_the_sword_against_armor() -> void:
	assert_gt(_hit(WARHAMMER, MERCENARY), _hit(SWORD, MERCENARY) * 2.0)


func test_warhammer_one_shots_skeletons() -> void:
	assert_gte(_hit(WARHAMMER, SKELETON), SKELETON.max_health)


func test_francisca_is_thrown_and_uses_axes() -> void:
	assert_eq(FRANCISCA.damage_type, Damage.Type.THROWN)
	assert_eq(FRANCISCA.ammo_type, &"axes")
	assert_eq(FRANCISCA.ammo_cost, 1)


func test_francisca_hits_harder_than_any_arrow() -> void:
	assert_gt(FRANCISCA.damage, BOW.damage)
	assert_gt(FRANCISCA.damage, BOW.max_charge_damage)


func test_francisca_arcs_and_falls_short_of_the_bow() -> void:
	assert_gt(FRANCISCA.projectile_gravity, BOW.projectile_gravity * 5.0)
	assert_lt(
		_level_range(FRANCISCA.projectile_speed, FRANCISCA.projectile_gravity),
		_level_range(BOW.projectile_speed, BOW.projectile_gravity) * 0.5
	)


func test_thrown_axe_spins() -> void:
	var axe: Node = FRANCISCA.projectile_scene.instantiate()
	assert_true(axe is SpinningProjectile)
	assert_not_null(axe.get_node_or_null("Spin"))
	axe.free()
