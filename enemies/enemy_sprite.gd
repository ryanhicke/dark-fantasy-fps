class_name EnemySprite
extends MeshInstance3D
## Placeholder enemy visuals: a flat billboarded quad that changes color
## for windup, pain, and death, and squashes or stretches vertically to
## lie down, stand up, or climb out of the ground.
##
## Kept apart from Enemy so real sprite animation can replace this one
## node (and script) without touching the AI. Needs a material_override
## that is local to scene, so color changes stay per-enemy.

@export var pain_color: Color = Color(1.0, 0.15, 0.1)
@export var windup_color: Color = Color(1.0, 0.9, 0.5)
@export var corpse_color: Color = Color(0.2, 0.15, 0.12)
@export var hit_flash_duration: float = 0.15
## Height multiplier once dead, so the corpse reads as lying down.
@export var corpse_height_scale: float = 0.25
@export var corpse_collapse_time: float = 0.2
## Seconds a dormant enemy takes to climb out of the ground.
@export var rise_time: float = 0.8
## Height multiplier while dormant. Not 0: a zero scale makes the
## billboard's basis degenerate.
@export var dormant_height_scale: float = 0.01

var _base_color: Color
var _color_tween: Tween

@onready var _material: StandardMaterial3D = get_active_material(0) as StandardMaterial3D


func _ready() -> void:
	_base_color = _material.albedo_color


## Alpha 0 keeps the current base color (see EnemyData.placeholder_color).
func set_base_color(color: Color) -> void:
	if color.a > 0.0:
		_base_color = color


func show_state(state: EnemyBrain.State, winding_up: bool) -> void:
	_kill_color_tween()
	_material.albedo_color = _color_for(state, winding_up)


## Flashes the pain color, then fades back to the color for [param state].
func flash_pain(state: EnemyBrain.State, winding_up: bool) -> void:
	_kill_color_tween()
	_material.albedo_color = pain_color
	_color_tween = create_tween()
	_color_tween.tween_property(_material, "albedo_color", _color_for(state, winding_up), hit_flash_duration)


## Returns the tween so callers can chain on it (e.g. a second phase).
func collapse() -> Tween:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale:y", corpse_height_scale, corpse_collapse_time)
	return tween


func stand_up() -> Tween:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale:y", 1.0, corpse_collapse_time)
	return tween


func hide_in_ground() -> void:
	visible = false
	scale.y = dormant_height_scale


func climb_out() -> Tween:
	visible = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale:y", 1.0, rise_time)
	return tween


func _color_for(state: EnemyBrain.State, winding_up: bool) -> Color:
	match state:
		EnemyBrain.State.PAIN:
			return pain_color
		EnemyBrain.State.DIE:
			return corpse_color
		EnemyBrain.State.ATTACK:
			return windup_color if winding_up else _base_color
	return _base_color


func _kill_color_tween() -> void:
	if _color_tween != null:
		_color_tween.kill()
		_color_tween = null
