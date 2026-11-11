class_name HomingLock
extends RefCounted
## Picks what a player's homing spell locks onto when cast: the
## HomingProjectile.TARGET_GROUP member closest to the crosshair, within a
## cone and range, that the caster can see. Runs once per cast, never per
## frame.


## Indices of [param points] inside the cone ([param max_angle] radians
## from [param forward]) and within [param max_range] of [param origin],
## closest to the crosshair first. Pure math so it can be unit tested.
static func candidates_by_angle(
	origin: Vector3,
	forward: Vector3,
	points: Array[Vector3],
	max_angle: float,
	max_range: float
) -> Array[int]:
	var found: Array[int] = []
	var angles: Dictionary[int, float] = {}
	for i: int in points.size():
		var offset: Vector3 = points[i] - origin
		var distance: float = offset.length()
		if distance <= 0.0 or distance > max_range:
			continue
		var angle: float = forward.angle_to(offset)
		if angle <= max_angle:
			found.append(i)
			angles[i] = angle
	found.sort_custom(func(a: int, b: int) -> bool: return angles[a] < angles[b])
	return found


## The best visible target, or null. [param sight] is a disabled RayCast3D
## that excludes the caster; it is updated once per candidate checked.
static func find_target(
	tree: SceneTree,
	origin: Vector3,
	forward: Vector3,
	max_angle: float,
	max_range: float,
	sight: RayCast3D
) -> Node3D:
	var targets: Array[Node3D] = []
	var points: Array[Vector3] = []
	for node: Node in tree.get_nodes_in_group(HomingProjectile.TARGET_GROUP):
		var target: Node3D = node as Node3D
		if target == null or not target.call(&"can_be_targeted"):
			continue
		targets.append(target)
		points.append(target.call(&"get_aim_point"))
	for index: int in candidates_by_angle(origin, forward, points, max_angle, max_range):
		sight.global_position = origin
		sight.target_position = sight.to_local(points[index])
		sight.force_raycast_update()
		if not sight.is_colliding() or sight.get_collider() == targets[index]:
			return targets[index]
	return null
