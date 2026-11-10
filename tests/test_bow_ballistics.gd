extends GutTest
## Pins the design spec for the starting bow (a 40 lb draw):
## - a level shot from eye height lands about 100 yards away,
## - a full 2 second draw shoots about 10% further.
## Uses the same integration step the game uses, at the physics tick rate.

const BOW_PATH: String = "res://weapons/bow/bow.tres"
const EYE_HEIGHT: float = 1.6
const PHYSICS_DELTA: float = 1.0 / 60.0
const YARD: float = 0.9144
const TARGET_RANGE: float = 100.0 * YARD
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


func test_quick_shot_reaches_about_100_yards() -> void:
	var distance: float = _level_shot_range(_bow.projectile_speed)
	assert_almost_eq(distance, TARGET_RANGE, TARGET_RANGE * RANGE_TOLERANCE,
		"quick shot range %.1f m (%.0f yd)" % [distance, distance / YARD])


func test_full_draw_shoots_about_10_percent_further() -> void:
	var quick: float = _level_shot_range(_bow.projectile_speed)
	var full: float = _level_shot_range(_bow.max_charge_speed)
	assert_almost_eq(full / quick, 1.10, 0.01,
		"full draw range %.1f m (%.0f yd)" % [full, full / YARD])


func test_full_draw_takes_two_seconds_and_hits_harder() -> void:
	assert_eq(_bow.charge_time, 2.0)
	assert_gt(_bow.max_charge_damage, _bow.damage)
