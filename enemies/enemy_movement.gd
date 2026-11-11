class_name EnemyMovement
extends RefCounted
## Doom-style chase movement: straight at the target, no pathfinding.
## Pure static math so it can be unit tested without physics.

## A flyer this close to its hover point stops instead of jittering around it.
const HOVER_ARRIVE_DISTANCE: float = 0.3


## Ground enemies: horizontal chase plus gravity. Keeps vertical velocity
## (falling) from [param current]; horizontal speed is all-or-nothing.
static func ground_velocity(
	current: Vector3,
	from: Vector3,
	target: Vector3,
	speed: float,
	chasing: bool,
	on_floor: bool,
	gravity: float,
	delta: float
) -> Vector3:
	var result: Vector3 = Vector3(0.0, current.y, 0.0)
	if not on_floor:
		result.y -= gravity * delta
	if chasing:
		var to_target: Vector3 = target - from
		to_target.y = 0.0
		if to_target != Vector3.ZERO:
			var horizontal: Vector3 = to_target.normalized() * speed
			result.x = horizontal.x
			result.z = horizontal.z
	return result


## Flyers: no gravity; chase straight toward a point [param hover_height]
## above the target, and hang still when not chasing.
static func flying_velocity(
	from: Vector3,
	target: Vector3,
	hover_height: float,
	speed: float,
	chasing: bool
) -> Vector3:
	if not chasing:
		return Vector3.ZERO
	var to_goal: Vector3 = target + Vector3.UP * hover_height - from
	if to_goal.length() <= HOVER_ARRIVE_DISTANCE:
		return Vector3.ZERO
	return to_goal.normalized() * speed
