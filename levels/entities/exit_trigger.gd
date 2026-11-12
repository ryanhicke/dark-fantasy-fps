class_name ExitTrigger
extends Area3D
## Invisible brush volume (TrenchBroom trigger_exit). The player walking in
## completes the level.
##
## With "boss" set, the exit stays closed until an enemy in the boss group
## dies, then appears as a glowing portal filling the brush.

## Bosses (necromancer, great demon) are tagged with this group in their scenes.
const BOSS_GROUP: StringName = &"boss"

## Filled by FuncGodot at map build; boss (0/1) overrides the export below.
@export var func_godot_properties: Dictionary = {}
@export var wait_for_boss: bool = false
@export var portal_color: Color = Color(0.9, 0.25, 0.15, 1)

var is_open: bool = true

var _triggered: bool = false


func _enter_tree() -> void:
	add_to_group(SaveSnapshot.SAVEABLE_GROUP)


func _ready() -> void:
	if func_godot_properties.has("boss"):
		wait_for_boss = int(func_godot_properties["boss"]) != 0
	body_entered.connect(_on_body_entered)
	if wait_for_boss:
		is_open = false
		set_deferred("monitoring", false)
		EventBus.enemy_killed.connect(_on_enemy_killed)


func _on_enemy_killed(enemy: Node) -> void:
	if not enemy.is_in_group(BOSS_GROUP):
		return
	EventBus.enemy_killed.disconnect(_on_enemy_killed)
	open()


## Saveable contract. Only a boss exit changes; the boss being dead in the
## save never re-sends enemy_killed, so the exit restores itself.
func save_state() -> Dictionary:
	return {"open": is_open}


func load_state(state: Dictionary) -> void:
	if bool(state.get("open", false)) and not is_open:
		open(true)


## Shows the portal and lets the player through. [param silent] skips the
## sound (restoring a save).
func open(silent: bool = false) -> void:
	if is_open:
		return
	is_open = true
	if EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.disconnect(_on_enemy_killed)
	_add_portal_visual()
	if not silent:
		AudioManager.play_sfx_at(AudioManager.sounds.portal_open, global_transform * _local_bounds().get_center())
	# Deferred: this can run inside the boss's physics callback.
	set_deferred("monitoring", true)


func _on_body_entered(body: Node3D) -> void:
	if _triggered or not is_open or not body is Player:
		return
	_triggered = true
	# On the UI pool: the intermission pauses the game right away, which
	# would pause a game sound before it was heard.
	AudioManager.play_ui(AudioManager.sounds.level_exit)
	EventBus.level_completed.emit()


## An unshaded box over the brush's bounds. Built once, when the portal opens.
func _add_portal_visual() -> void:
	var bounds: AABB = _local_bounds()
	if bounds.size == Vector3.ZERO:
		return
	var box: BoxMesh = BoxMesh.new()
	box.size = bounds.size
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = portal_color
	box.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.mesh = box
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.position = bounds.get_center()
	add_child(visual)


func _local_bounds() -> AABB:
	for child: Node in get_children():
		var shape_node: CollisionShape3D = child as CollisionShape3D
		if shape_node == null or shape_node.shape == null:
			continue
		var points: PackedVector3Array = PackedVector3Array()
		var convex: ConvexPolygonShape3D = shape_node.shape as ConvexPolygonShape3D
		if convex != null:
			points = convex.points
		var box: BoxShape3D = shape_node.shape as BoxShape3D
		if box != null:
			return AABB(shape_node.position - box.size * 0.5, box.size)
		if points.is_empty():
			continue
		var bounds: AABB = AABB(points[0], Vector3.ZERO)
		for point: Vector3 in points:
			bounds = bounds.expand(point)
		return shape_node.transform * bounds
	return AABB()
