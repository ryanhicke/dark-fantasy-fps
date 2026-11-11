class_name LightningBolt
extends Node3D
## Visual-only lightning bolt: a few thin unshaded boxes zig-zagging from
## start to end, then thinning out and freeing itself. No real-time light
## (CLAUDE.md rules 4-5); the HUD screen flash sells the hit.
##
## Children named Segment1..SegmentN (MeshInstance3D with a 1 m BoxMesh
## along Z) are laid end to end along the path at strike().

## Meters the bolt's joints may wander sideways from the straight line.
@export var jitter: float = 0.25
## Seconds the bolt stays before it has fully thinned out.
@export var lifetime: float = 0.15

var _segments: Array[MeshInstance3D] = []


func _ready() -> void:
	for child: Node in get_children():
		var segment: MeshInstance3D = child as MeshInstance3D
		if segment != null:
			_segments.append(segment)


## Lays the bolt from [param from] to [param to] (global positions) and
## starts its fade. Call after adding it to the tree.
func strike(from: Vector3, to: Vector3) -> void:
	global_position = Vector3.ZERO
	var count: int = _segments.size()
	if count == 0 or from.is_equal_approx(to):
		queue_free()
		return
	var direction: Vector3 = (to - from).normalized()
	var side: Vector3 = direction.cross(Vector3.UP)
	if side.is_zero_approx():
		side = Vector3.RIGHT
	side = side.normalized()
	var lift: Vector3 = side.cross(direction).normalized()
	var start: Vector3 = from
	for i: int in count:
		var t: float = float(i + 1) / float(count)
		var end: Vector3 = from.lerp(to, t)
		# Ends stay exact so the bolt visibly leaves the caster and reaches
		# what it hit; only the joints in between wander.
		if i < count - 1:
			end += side * randf_range(-jitter, jitter) + lift * randf_range(-jitter, jitter)
		_place(_segments[i], start, end)
		start = end
	var fade: Tween = create_tween()
	fade.tween_method(_thin, 1.0, 0.0, lifetime)
	fade.tween_callback(queue_free)


func _place(segment: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var length: float = start.distance_to(end)
	segment.global_position = (start + end) * 0.5
	var forward: Vector3 = (end - start).normalized()
	var up: Vector3 = Vector3.UP if absf(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	segment.look_at(segment.global_position + forward, up)
	segment.scale = Vector3(1.0, 1.0, length)


func _thin(amount: float) -> void:
	for segment: MeshInstance3D in _segments:
		segment.scale.x = amount
		segment.scale.y = amount
