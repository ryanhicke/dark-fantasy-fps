extends GutTest
## EnemyMovement chase math (ground and flying).

const SPEED: float = 4.0
const GRAVITY: float = 15.0
const DELTA: float = 1.0 / 60.0
const HOVER: float = 2.5


func test_ground_chase_is_horizontal_at_full_speed() -> void:
	var v: Vector3 = EnemyMovement.ground_velocity(
		Vector3.ZERO, Vector3.ZERO, Vector3(3.0, 5.0, -4.0), SPEED, true, true, GRAVITY, DELTA
	)
	assert_almost_eq(Vector2(v.x, v.z).length(), SPEED, 0.0001)
	assert_eq(v.y, 0.0, "target height doesn't lift a ground enemy")


func test_ground_not_chasing_stops_but_keeps_falling() -> void:
	var v: Vector3 = EnemyMovement.ground_velocity(
		Vector3(2.0, -1.0, 2.0), Vector3.ZERO, Vector3.FORWARD, SPEED, false, false, GRAVITY, DELTA
	)
	assert_eq(v.x, 0.0)
	assert_eq(v.z, 0.0)
	assert_almost_eq(v.y, -1.0 - GRAVITY * DELTA, 0.0001)


func test_flyer_heads_for_point_above_target() -> void:
	var target: Vector3 = Vector3(0.0, 0.0, -10.0)
	var v: Vector3 = EnemyMovement.flying_velocity(Vector3.ZERO, target, HOVER, SPEED, true)
	assert_almost_eq(v.length(), SPEED, 0.0001)
	assert_almost_eq(v.normalized().angle_to(target + Vector3.UP * HOVER), 0.0, 0.0001)


func test_flyer_hangs_still_when_arrived_or_idle() -> void:
	var at_goal: Vector3 = Vector3.UP * HOVER
	assert_eq(EnemyMovement.flying_velocity(at_goal, Vector3.ZERO, HOVER, SPEED, true), Vector3.ZERO)
	assert_eq(EnemyMovement.flying_velocity(Vector3.ZERO, Vector3.FORWARD * 10.0, HOVER, SPEED, false), Vector3.ZERO)
