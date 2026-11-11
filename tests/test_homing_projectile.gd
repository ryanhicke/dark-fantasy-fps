extends GutTest
## Steering math for HomingProjectile (imp missiles, later the player's wand).

const SPEED: float = 12.0


func test_turns_at_most_max_angle() -> void:
	var velocity: Vector3 = Vector3.FORWARD * SPEED
	var steered: Vector3 = HomingProjectile.steer(velocity, Vector3.RIGHT, 0.1)
	assert_almost_eq(velocity.angle_to(steered), 0.1, 0.0001)


func test_snaps_when_within_max_angle() -> void:
	var desired: Vector3 = Vector3(0.05, 0.0, -1.0)
	var steered: Vector3 = HomingProjectile.steer(Vector3.FORWARD * SPEED, desired, 0.5)
	assert_almost_eq(steered.angle_to(desired), 0.0, 0.0001)


func test_keeps_speed() -> void:
	var steered: Vector3 = HomingProjectile.steer(Vector3.FORWARD * SPEED, Vector3.UP + Vector3.RIGHT, 0.3)
	assert_almost_eq(steered.length(), SPEED, 0.0001)


func test_zero_turn_flies_straight() -> void:
	var velocity: Vector3 = Vector3.FORWARD * SPEED
	assert_eq(HomingProjectile.steer(velocity, Vector3.RIGHT, 0.0), velocity)


func test_reads_turn_rate_from_spell_data() -> void:
	var spell: SpellData = SpellData.new()
	spell.homing_turn_rate = 1.25
	var missile: HomingProjectile = HomingProjectile.new()
	missile.apply_weapon_data(spell)
	assert_eq(missile.turn_rate, 1.25)
	missile.free()
