extends GutTest
## Fireball splash math and the design values in fireball.tres.

const FIREBALL_PATH: String = "res://spells/fireball/fireball.tres"
const RADIUS: float = 2.5
const MAX_DAMAGE: float = 20.0

var _fireball: SpellData


func before_all() -> void:
	_fireball = load(FIREBALL_PATH) as SpellData


func test_splash_is_full_at_center() -> void:
	assert_almost_eq(FireballProjectile.splash_damage_at(0.0, RADIUS, MAX_DAMAGE), MAX_DAMAGE, 0.001)


func test_splash_falls_off_linearly() -> void:
	assert_almost_eq(FireballProjectile.splash_damage_at(RADIUS * 0.5, RADIUS, MAX_DAMAGE), MAX_DAMAGE * 0.5, 0.001)


func test_no_splash_at_or_beyond_radius() -> void:
	assert_eq(FireballProjectile.splash_damage_at(RADIUS, RADIUS, MAX_DAMAGE), 0.0)
	assert_eq(FireballProjectile.splash_damage_at(RADIUS * 2.0, RADIUS, MAX_DAMAGE), 0.0)


func test_zero_radius_means_no_splash() -> void:
	assert_eq(FireballProjectile.splash_damage_at(0.0, 0.0, MAX_DAMAGE), 0.0)


func test_fireball_costs_mana_and_deals_fire_damage() -> void:
	assert_not_null(_fireball, "fireball.tres loads as SpellData")
	assert_eq(_fireball.ammo_type, &"mana")
	assert_gt(_fireball.ammo_cost, 0)
	assert_eq(_fireball.damage_type, Damage.Type.FIRE)


func test_fireball_splash_hurts_caster_at_half_damage() -> void:
	assert_gt(_fireball.splash_radius, 0.0)
	assert_gt(_fireball.splash_damage, 0.0)
	assert_eq(_fireball.caster_splash_scale, 0.5)


func test_fireball_flies_straight_and_uses_fireball_scene() -> void:
	assert_eq(_fireball.projectile_gravity, 0.0)
	var projectile: Node = _fireball.projectile_scene.instantiate()
	assert_true(projectile is FireballProjectile)
	projectile.free()
