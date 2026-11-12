class_name Lever
extends StaticBody3D
## A wall lever (TrenchBroom func_lever). Pulled once with the use key; it
## then triggers every door whose targetname matches its target.
##
## "marked" levers carry the necromancer's bone mark (the Mark child), so
## players who look closely can tell real levers from the trap lever. The
## mark shows on both faces, so the lever reads the same from any side.

signal pulled

## Filled by FuncGodot at map build; target and marked override the exports.
@export var func_godot_properties: Dictionary = {}
@export var target: String = ""
@export var marked: bool = false
## Handle swing in degrees, from up to down.
@export var pull_angle: float = 90.0
@export var pull_time: float = 0.25

var is_pulled: bool = false

@onready var _handle: Node3D = $Handle
@onready var _mark: Node3D = $Mark


func _enter_tree() -> void:
	add_to_group(SaveSnapshot.SAVEABLE_GROUP)


func _ready() -> void:
	if func_godot_properties.has("target"):
		target = str(func_godot_properties["target"])
	if func_godot_properties.has("marked"):
		marked = int(func_godot_properties["marked"]) != 0
	_mark.visible = marked


## Saveable contract. The doors it opened save their own state, so a
## restored lever only needs to look pulled.
func save_state() -> Dictionary:
	return {"pulled": is_pulled}


func load_state(state: Dictionary) -> void:
	if bool(state.get("pulled", false)) and not is_pulled:
		is_pulled = true
		_handle.rotation_degrees.x += pull_angle


func use(_user: Node) -> void:
	if is_pulled:
		return
	is_pulled = true
	var swing: Tween = create_tween()
	swing.tween_property(_handle, "rotation_degrees:x", _handle.rotation_degrees.x + pull_angle, pull_time)
	AudioManager.play_sfx_at(AudioManager.sounds.lever_pull, _handle.global_position)
	pulled.emit()
	if target.is_empty():
		return
	# Looked up once per pull, never per frame.
	for node: Node in get_tree().get_nodes_in_group(Door.TRIGGER_GROUP):
		var door: Door = node as Door
		if door != null and door.targetname == target:
			door.trigger()
