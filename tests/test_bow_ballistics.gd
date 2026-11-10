extends GutTest
## Pins the design spec for the starting bow (a 40 lb draw):
## - a level shot from eye height lands about 80 yards away,
## - a full 1.5 second draw lands about 110 yards away and hits harder.
## Uses the same integration step the game uses, at the physics tick rate.

const BOW_PATH: String = "res://weapons/bow/bow.tres"
const EYE_HEIGHT: float = 1.6
const PHYSICS_DELTA: float = 1.0 / 60.0
const YARD: float = 0.9144
const QUICK_SHOT_RANGE: float = 80.0 * YARD
const FULL_DRAW_RANGE: float = 110.0 * YARD
const FULL_DRAW_TIME: float = 1.5
const RANGE_TOLERANCE: float = 0.03

var _bow: WeaponData


func before_all() -> void:
	_bow = load(BOW_PATH) as WeaponData


## Horizontal distance travelled before dropping from eye height to the floor.
func _level_shot_range(speed: float) -> float:
	var position: Vector3 = Vector3(0.0, EYE_HEIGHT, 0.0)
	var velocity: Vector3 = Vector3.FORWARD * speed
	while position.y > 0.0:
		velocity = Projectile.integrate_velocity(velocity, _bow.projectile_gravity, PHYSICS_DELTA)
		position += velocity * PHYSICS_DELTA
	return Vector2(position.x, position.z).length()


func test_quick_shot_reaches_about_80_yards() -> void:
	var distance: float = _level_shot_range(_bow.projectile_speed)
	assert_almost_eq(distance, QUICK_SHOT_RANGE, QUICK_SHOT_RANGE * RANGE_TOLERANCE,
		"quick shot range %.1f m (%.0f yd)" % [distance, distance / YARD])


func test_full_draw_reaches_about_110_yards() -> void:
	var distance: float = _level_shot_range(_bow.max_charge_speed)
	assert_almost_eq(distance, FULL_DRAW_RANGE, FULL_DRAW_RANGE * RANGE_TOLERANCE,
		"full draw range %.1f m (%.0f yd)" % [distance, distance / YARD])


func test_full_draw_takes_one_and_a_half_seconds_and_hits_harder() -> void:
	assert_eq(_bow.charge_time, FULL_DRAW_TIME)
	assert_gt(_bow.max_charge_damage, _bow.damage)
