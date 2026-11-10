class_name EffectPrewarmer
extends Node3D
## Removes the hitch the first time an effect appears (e.g. the first
## fireball) by drawing every listed effect's meshes once during level load.
##
## The Compatibility renderer compiles a material's shader the first time it
## is drawn. Drawing tiny copies here moves that compile into level load,
## where a dropped frame isn't noticed.
##
## Only the meshes are copied, never the scenes themselves, so effect scripts
## (flight, damage, explosions) never run.

## Frames to keep the copies drawn. One is enough to compile; the extra one
## covers a frame where the camera wasn't active yet.
const FRAMES_TO_DRAW: int = 2
## Copies sit this fraction of the way to the camera's far plane: inside the
## view (so they are drawn and their shaders compile) but so distant they
## cover less than a pixel, and are usually hidden behind level walls.
## Distance does this, not scale, because billboard materials without
## billboard_keep_scale (like the fireball's) ignore node scale.
const FAR_PLANE_FRACTION: float = 0.9
## Shrinks the non-billboard meshes (e.g. arrows) further.
const SCALE: float = 0.001

var _frames_left: int = FRAMES_TO_DRAW


## Adds copies of every mesh in [param scenes] in front of [param camera].
## Frees itself once they've been drawn.
static func start(camera: Camera3D, scenes: Array[PackedScene]) -> EffectPrewarmer:
	var prewarmer: EffectPrewarmer = EffectPrewarmer.new()
	prewarmer.name = "EffectPrewarmer"
	prewarmer.position = Vector3.FORWARD * camera.far * FAR_PLANE_FRACTION
	prewarmer.scale = Vector3.ONE * SCALE
	for scene: PackedScene in scenes:
		for mesh: MeshInstance3D in copy_meshes(scene):
			prewarmer.add_child(mesh)
	camera.add_child(prewarmer)
	return prewarmer


## Returns script-free copies of every MeshInstance3D in [param scene], with
## the same mesh and materials (including overrides).
static func copy_meshes(scene: PackedScene) -> Array[MeshInstance3D]:
	var copies: Array[MeshInstance3D] = []
	if scene == null:
		return copies
	# Never added to the tree, so its scripts' _ready never runs.
	var instance: Node = scene.instantiate()
	_collect(instance, copies)
	instance.free()
	return copies


static func _collect(node: Node, copies: Array[MeshInstance3D]) -> void:
	var source: MeshInstance3D = node as MeshInstance3D
	if source != null and source.mesh != null:
		var copy: MeshInstance3D = MeshInstance3D.new()
		copy.mesh = source.mesh
		copy.material_override = source.material_override
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface: int in source.get_surface_override_material_count():
			copy.set_surface_override_material(surface, source.get_surface_override_material(surface))
		copies.append(copy)
	for child: Node in node.get_children():
		_collect(child, copies)


func _process(_delta: float) -> void:
	_frames_left -= 1
	if _frames_left <= 0:
		queue_free()
