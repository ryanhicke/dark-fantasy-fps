class_name EnemySprite
extends MeshInstance3D
## Enemy visuals on one billboarded quad. With an EnemySpriteSheet it shows
## animation frames by moving the material's UV window over the sheet;
## without one it is the flat placeholder that changes color for windup,
## pain, and death, and squashes vertically to lie down.
##
## Kept apart from Enemy so the AI never deals with visuals. Needs a
## material_override that is local to scene, so changes stay per-enemy.

@export var pain_color: Color = Color(1.0, 0.15, 0.1)
@export var windup_color: Color = Color(1.0, 0.9, 0.5)
@export var corpse_color: Color = Color(0.2, 0.15, 0.12)
@export var hit_flash_duration: float = 0.15
## Height multiplier once dead, so the placeholder corpse reads as lying down.
@export var corpse_height_scale: float = 0.25
@export var corpse_collapse_time: float = 0.2
## Seconds a dormant enemy takes to climb out of the ground.
@export var rise_time: float = 0.8
## Height multiplier while dormant. Not 0: a zero scale makes the
## billboard's basis degenerate.
@export var dormant_height_scale: float = 0.01
## Cut-off for the sheet's transparent pixels. Scissor (not blending) keeps
## sprites out of the transparent sort and cheap on integrated GPUs.
@export var alpha_scissor_threshold: float = 0.5

var _base_color: Color
var _placeholder_color: Color
var _color_tween: Tween
## Only one height (or death) animation at a time; a pooled enemy may be
## reused while its corpse is still collapsing.
var _shape_tween: Tween

var _sheet: EnemySpriteSheet
var _anim: PackedInt32Array = PackedInt32Array()
var _anim_time: float = 0.0
var _frame: int = -1

@onready var _material: StandardMaterial3D = get_active_material(0) as StandardMaterial3D


func _ready() -> void:
	_placeholder_color = _material.albedo_color
	_base_color = _placeholder_color
	set_process(false)


## Null switches back to the flat placeholder (e.g. a disguised werewolf
## rising as an enemy that has no art yet).
func set_sheet(sheet: EnemySpriteSheet) -> void:
	_sheet = sheet
	_frame = -1
	_stop_anim()
	if sheet == null or sheet.texture == null:
		_sheet = null
		_material.albedo_texture = null
		_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_material.uv1_scale = Vector3.ONE
		_material.uv1_offset = Vector3.ZERO
		_base_color = _placeholder_color
		return
	_material.albedo_texture = sheet.texture
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_material.alpha_scissor_threshold = alpha_scissor_threshold
	_material.uv1_scale = Vector3(1.0 / sheet.columns, 1.0 / sheet.rows, 1.0)
	_base_color = Color.WHITE
	scale.y = 1.0


## Alpha 0 keeps the current base color (see EnemyData.placeholder_color).
## Ignored while a sheet is shown: the art carries the color.
func set_base_color(color: Color) -> void:
	if _sheet == null and color.a > 0.0:
		_base_color = color


func show_state(state: EnemyBrain.State, winding_up: bool) -> void:
	_kill_color_tween()
	_material.albedo_color = _color_for(state, winding_up)
	if _sheet != null:
		_play(_frames_for(state, winding_up))


## Flashes the pain color, then fades back to the color for [param state].
func flash_pain(state: EnemyBrain.State, winding_up: bool) -> void:
	_kill_color_tween()
	_material.albedo_color = pain_color
	_color_tween = create_tween()
	_color_tween.tween_property(_material, "albedo_color", _color_for(state, winding_up), hit_flash_duration)


## Returns the tween so callers can chain on it (e.g. a second phase).
func collapse() -> Tween:
	if _sheet == null:
		return _animate_height(corpse_height_scale, corpse_collapse_time)
	_stop_anim()
	_kill_shape_tween()
	var count: int = maxi(1, _sheet.death_frames.size())
	_shape_tween = create_tween()
	_shape_tween.tween_method(_show_death_progress, 0.0, 1.0, count / _sheet.death_fps)
	return _shape_tween


func stand_up() -> Tween:
	if _sheet != null:
		_play(_sheet.idle_frames)
	return _animate_height(1.0, corpse_collapse_time)


func hide_in_ground() -> void:
	_kill_shape_tween()
	visible = false
	scale.y = dormant_height_scale


func climb_out() -> Tween:
	visible = true
	return _animate_height(1.0, rise_time)


func _process(delta: float) -> void:
	# Only runs while a looping animation (the walk) has several frames.
	_anim_time += delta
	var index: int = int(_anim_time * _sheet.walk_fps) % _anim.size()
	_set_frame(_anim[index])


func _play(frames: PackedInt32Array) -> void:
	if frames.is_empty():
		return
	if frames == _anim and is_processing():
		return  # Already looping this one; don't restart the walk cycle.
	_anim = frames
	_anim_time = 0.0
	_set_frame(frames[0])
	set_process(frames.size() > 1)


func _stop_anim() -> void:
	set_process(false)
	_anim = PackedInt32Array()


func _show_death_progress(t: float) -> void:
	var frames: PackedInt32Array = _sheet.death_frames
	if frames.is_empty():
		return
	_set_frame(frames[mini(int(t * frames.size()), frames.size() - 1)])


func _set_frame(index: int) -> void:
	if index == _frame:
		return
	_frame = index
	var col: int = index % _sheet.columns
	var row: int = index / _sheet.columns
	_material.uv1_offset = Vector3(float(col) / _sheet.columns, float(row) / _sheet.rows, 0.0)


func _frames_for(state: EnemyBrain.State, winding_up: bool) -> PackedInt32Array:
	match state:
		EnemyBrain.State.CHASE:
			return _sheet.walk_frames
		EnemyBrain.State.ATTACK:
			return _sheet.windup_frames if winding_up else _sheet.attack_frames
		EnemyBrain.State.PAIN:
			return _sheet.pain_frames
		EnemyBrain.State.DIE:
			return _sheet.death_frames.slice(0, 1)
	return _sheet.idle_frames


func _animate_height(height_scale: float, duration: float) -> Tween:
	_kill_shape_tween()
	_shape_tween = create_tween()
	_shape_tween.tween_property(self, "scale:y", height_scale, duration)
	return _shape_tween


func _kill_shape_tween() -> void:
	if _shape_tween != null:
		_shape_tween.kill()
		_shape_tween = null


func _kill_color_tween() -> void:
	if _color_tween != null:
		_color_tween.kill()
		_color_tween = null


func _color_for(state: EnemyBrain.State, winding_up: bool) -> Color:
	# With art, the frames show the state; only hits tint the sprite.
	if _sheet != null:
		return _base_color
	match state:
		EnemyBrain.State.PAIN:
			return pain_color
		EnemyBrain.State.DIE:
			return corpse_color
		EnemyBrain.State.ATTACK:
			return windup_color if winding_up else _base_color
	return _base_color
